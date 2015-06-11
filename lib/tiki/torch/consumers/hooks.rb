module Tiki
  module Torch
    class Consumer
      module Hooks

        def self.included(base)
          base.send :attr_reader, :success, :failure, :back_off
        end

        def process
          debug "Event ##{short_id} was processed"
        end

        def on_start
          debug "Event ##{short_id} started"
        end

        def on_success(result)
          info "Event ##{short_id} succeeded with #{result.inspect}"
          @success = result
          event.finish
        end

        def on_failure(exception)
          error "Event ##{short_id} failed with #{exception.class.name} : #{exception.message}\n  #{exception.backtrace[0, 5].join("\n  ")}"
          @failure = exception

          back_off_event || dlq_event || finish_event
        end

        def on_end
          debug "Event ##{short_id} ended"
        end

        private

        def dlq_event
          debug "Event ##{short_id} will NOT be sent to a dead letter queue ..."
          false
        end

        def finish_event
          info "Event ##{short_id} will NOT be requeued ..."
          event.finish
        end

      end
    end
  end
end
