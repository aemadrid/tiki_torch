module Tiki
  module Torch
    module Publishing
      module Retries
        class Entry
          def initialize(topic_name, event)
            @topic_name = topic_name
            @event = event
            @tries = 1
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

        extend self

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
            count = Torch.config.retry_size
            puts "> executor | count : #{count}"
            while count > 0 && entries.size > 0
              count += 1
              key = entries.first
              entry = entries[key]
              if entry
                Torch.publisher.publish(entry.topic_name, entry.event)
                puts "> executor | published #{key} ..."
              else
                puts "> executor | key #{key} was missing ..."
              end
            end
          end
        end

        def default_proc
          Proc.new do |_e, topic_name, event|
            puts "> publishing again [#{topic_name}] (#{event.class.name}) #{event.inspect}"
            Tiki::Torch::Publishing::Retries.add topic_name, event
          end
        end

        def setup(interval_secs = 5, interval_timeout = 2, size = 10, &blk)
          Torch.config.retry_interval_secs = interval_secs
          Torch.config.retry_timeout_secs = interval_timeout
          Torch.config.retry_size = size
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
