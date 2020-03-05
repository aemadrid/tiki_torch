# frozen_string_literal: true

module Tiki
  module Torch
    module Publishing
      class Retries
        class Entry
          attr_reader :topic_name, :event

          def initialize(topic_name, event)
            @topic_name = topic_name
            @event      = event
            @tries      = 1
          end

          def fingerprint
            @fingerprint ||= format '%s:%s',
                                    @topic_name.to_s,
                                    (@event.respond_to?(:fingerprint) ? @event.fingerprint : @event.to_s)
          end

          def increment_tries
            @tries += 1
          end
        end

        include Logging

        class << self
          def entries
            @entries ||= Concurrent::Hash.new
          end

          def add(topic_name, event)
            entry = Entry.new topic_name, event
            found = entries[entry.fingerprint]
            if found
              found.increment_tries
              found
            else
              entries[entry.fingerprint] = entry
            end
          end

          def executor
            @executor ||= Concurrent::TimerTask.new(
              execution_interval: Torch.config.retry_interval_secs,
              timeout_interval: Torch.config.retry_timeout_secs
            ) do
              keys = entries.keys[0, Torch.config.retry_size]
              keys.each do |key|
                entry = entries.delete key
                Torch.publisher.publish(entry.topic_name, entry.event) if entry
              end
            rescue Exception => e
              log_exception e, section: 'retries'
            end
          end

          def default_proc
            proc do |_e, topic_name, event|
              Tiki::Torch::Publishing::Retries.add topic_name, event
            end
          end

          def setup(interval_secs = 5, interval_timeout = 2, size = 10, &blk)
            Torch.config.retry_interval_secs      = interval_secs
            Torch.config.retry_timeout_secs       = interval_timeout
            Torch.config.retry_size               = size
            Torch.config.publishing_error_handler = blk || default_proc
            executor.execute
          end

          def disable
            executor.shutdown
            @executor = nil
          end
        end
      end
    end
  end
end
