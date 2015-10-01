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

          def pop_dlq_event
            msg = pop_dlq_message
            return nil unless msg

            Event.new msg
          end

          def pop_dlq_message
            dlq_poller.pop
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
          stats.increment :dead
          [:dlq, topic_name]
        end

      end
    end
  end
end
