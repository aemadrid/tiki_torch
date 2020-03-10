# frozen_string_literal: true

module Tiki
  module Torch
    module Publishing
      class Retries
        # Class to encapsulate failed attempts to publish an event to a topic
        #
        # @attr [String] topic_name
        # @attr [Object] event
        # @attr [Integer] tries
        class Entry
          attr_reader :topic_name, :event, :tries

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
          # This is informational only in that we do not stop retrying at the moment.
          def increment_tries
            @tries += 1
          end
        end

        include Logging

        class << self
          # A list of entries that failed to publish. The key is the fingerprint of the event.
          #
          # @return [Concurrent::Hash{String=>Tiki::Torch::Publishing::Retries::Entry}]
          def entries
            @entries ||= Concurrent::Hash.new
          end

          # Adds or increments an entry to the list. Runs the callback so the entry can be reported
          # or removed given the number of retries or other criteria
          #
          # @param [String] topic_name the name of the topic to retry
          # @param [Object] event the event to retry
          # @return [Tiki::Torch::Publishing::Retries::Entry] the job to retry
          def add(topic_name, event)
            entry = Entry.new topic_name, event
            found = entries[entry.fingerprint]
            if found
              found.increment_tries
              Torch.config.publishing_retry_handler.call entries, found
            else
              entries[entry.fingerprint] = entry
              Torch.config.publishing_retry_handler.call entries, entry
            end
          end

          # The callback to deal with the list of entries and the entry that was just added
          # to that list
          #
          # @param [Hash{String=>Tiki::Torch::Publishing::Retries::Entry}] _current_entries
          # @param [Tiki::Torch::Publishing::Retries::Entry] entry
          # @return [Tiki::Torch::Publishing::Retries::Entry]
          def default_retry_handler(_current_entries, entry)
            entry
          end

          # An executor to deal with retrying failed publishing jobs
          #
          # @return [Concurrent::TimerTask, nil]
          attr_reader :executor

          def build_executor
            Concurrent::TimerTask.new(
              execution_interval: Torch.config.retry_interval_secs,
              timeout_interval:   Torch.config.retry_timeout_secs
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

          # The default procedure to deal with an exception thrown while publishing
          # that adds the topic and event to be retried
          def default_error_handler(_exception, topic_name, event)
            Tiki::Torch::Publishing::Retries.add topic_name, event
          end

          # Setup a reappearing process that will every so many seconds retry publishing
          # previously failed jobs. This method will setup the executor to handle queueing
          # up the jobs to retry later. In any case it will replace any other
          # publishing_error_handler that was setup before. If ran twice it will return false
          # unless it's been disabled.
          #
          # @param [Hash{Symbol->Object}] options
          # @return [TrueClass, FalseClass] whether it was successfully setup retries
          def setup(options = {})
            return false if @executor

            Torch.config.retry_interval_secs = options.fetch :interval_secs, 5
            Torch.config.retry_timeout_secs  = options.fetch :interval_timeout, 2
            Torch.config.retry_count         = options.fetch :size, 10

            Torch.config.publishing_error_handler = options.fetch :error_handler, method(:default_error_handler)
            Torch.config.publishing_retry_handler = options.fetch :retry_handler, method(:default_retry_handler)

            @executor = build_executor.tap(&:execute)

            true
          end

          # @return [TrueClass, FalseClass] whether it was successfully disabled retries
          def disable
            return false if @executor.nil?

            @executor.shutdown if @executor.running?
            @executor = nil
            true
          end
        end
      end
    end
  end
end
