module Tiki
  module Torch
    class Consumer
      module Hooks

        def self.included(base)
          base.send :attr_reader, :success, :failure, :back_off
        end

        def on_start
        end

        def process
          debug "Event ##{short_id} was processed"
        end

        def on_success(result)
          @success  = result
          event.finish
        end

        def on_failure(exception)
          @failure  = exception
          back_off_event || dlq_event || finish_event
        end

        def on_rpc_response(result)
          respond_to = properties[:respond_to]
          request_id = properties[:request_message_id]

          debug_var :properties, properties
          return nil if respond_to.nil? || request_id.nil?

          Tiki::Torch.publish respond_to, result, request_message_id: request_id
          [:responded, respond_to, request_id]
        end

        def on_end
          debug "Event ##{short_id} ended"
        end

        private

        def dlq_event
          # @todo Add DLQ (Dead Letter Queue) processing ...
          false
        end

        def finish_event
          event.finish
          [:finished]
        end

      end
    end
  end
end
