module Tiki
  module Torch
    class Consumer
      module Hooks

        def self.included(base)
          base.send :attr_reader, :success, :failure
        end

        def on_start
        end

        def process
          debug "Event ##{short_id} was processed"
        end

        def on_success(result)
          @success = result
          event.finish
        end

        def on_failure(exception)
          @failure = exception
        end

        def on_end
          debug "Event ##{short_id} ended"
        end

      end
    end
  end
end
