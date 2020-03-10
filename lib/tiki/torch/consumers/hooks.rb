module Tiki
  module Torch
    class Consumer
      module Hooks

        def self.included(base)
          base.extend ClassMethods
          base.send :attr_reader, :success, :failure
        end

        module ClassMethods

          def pop_results(req_size, found_size, timeout)
            debug "req_size : #{req_size} | found_size : #{found_size} | timeout : #{timeout}"
          end

        end

        def on_start
        end

        def process
          info "Event ##{event.short_id} was processed"
        end

        def on_success(result)
          @success = result
          event.finish
        end

        def on_failure(exception)
          @failure = exception
        end

        def on_end
          debug "Event ##{event.short_id} ended in #{@success ? 'success' : 'failure'}"
        end

      end
    end
  end
end
