# frozen_string_literal: true

module Tiki
  module Torch
    module Publishing
      class Retries
        class Entry
          attr_reader :topic_name, :event

          # @param [String] topic_name the name of the topic to retry
          # @param [Object] event the event to retry
          def initialize(topic_name, event)
            @topic_name = topic_name
            @event      = event
            @tries      = 1
          end

          # @return [String] A unique identifier for the topic_name + event
          def fingerprint
            @fingerprint ||= format '%s:%s',
                                    @topic_name.to_s,
                                    (@event.respond_to?(:fingerprint) ? @event.fingerprint : @event.to_s)
          end

          # Increase the quantity of tries for the entry
          def increment_tries
            @tries += 1
          end
        end

        include Logging

        class << self
          # @return [Concurrent::Hash] a list of publishing jobs to retry
          def entries
            @entries ||= Concurrent::Hash.new
          end

          # @param [String] topic_name the name of the topic to retry
          # @param [Object] event the event to retry
          # @return [Tiki::Torch::Publishing::Retries::Entry] the job to retry
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

          # @return [Concurrent::TimerTask] an executor to deal with retrying failed
          # publishing jobs
          def executor
            @executor ||= Concurrent::TimerTask.new(
              execution_interval: Torch.config.retry_interval_secs,
              timeout_interval: Torch.config.retry_timeout_secs
            ) do
              keys = entries.keys[0, Torch.config.retry_count]
              keys.each do |key|
                entry = entries[key]
                if entry
                  Torch.publisher.publish(entry.topic_name, entry.event)
                  entries.delete key
                end
              end
            rescue Exception => e
              log_exception e, section: 'retries'
            end
          end

          # Setup a reappearing process that will every so many seconds retry publishing
          # previously failed jobs. This method will setup the executor to handle queueing
          # up the jobs to retry later. In any case it will replace any other
          # publishing_error_handler that was setup before. If ran twice it will return false
          # unless it's been disabled.
          #
          # @param [Integer] interval_secs
          # @param [Integer] interval_timeout
          # @param [Integer] size the number of failed jobs to retry at a time
          # @return [TrueClass, FalseClass] whether it was successfully setup retries
          def setup(interval_secs = 5, interval_timeout = 2, size = 10)
            return false if @executor

            Torch.config.retry_interval_secs      = interval_secs
            Torch.config.retry_timeout_secs       = interval_timeout
            Torch.config.retry_count              = size
            Torch.config.publishing_error_handler = proc do |_e, topic_name, event|
              Tiki::Torch::Publishing::Retries.add topic_name, event
            end
            executor.execute
            true
          end

          # @return [TrueClass, FalseClass] whether it was successfully disabled retries
          def disable
            return false if @executor

            executor.shutdown
            @executor = nil
            true
          end
        end
      end
    end
  end
end
