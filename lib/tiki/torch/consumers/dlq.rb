module Tiki
  module Torch
    class Consumer
      module DLQ

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods

          def dlq_poller
            @dlq_poller ||= ConsumerPoller.new topic: full_dlq_topic_name, channel: 'events'
          end

          def pop_dlq_event(timeout = 0.25)
            msg = pop_dlq_message(timeout)
            return nil unless msg

            Event.new msg
          end

          def pop_dlq_message(timeout)
            dlq_poller.pop timeout
          rescue ThreadError
            return nil
          end

        end

        private

        def dlq_event
          topic_name = self.class.dlq_topic
          options    = {
            topic:       self.class.topic,
            channel:     self.class.channel,
            exc_class:   @failure.class.name,
            exc_message: @failure.message,
            exc_trace:   @failure.backtrace[0, 20].join("\n")
          }
          event.finish
          publish topic_name, payload, options
          [:dlq, topic_name]
        end

      end
    end
  end
end
