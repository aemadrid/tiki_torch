module Tiki
  module Torch
    class Consumer
      module Monitoring

        def on_start
          @start_time = Time.now
          stats.increment :started
          monitor_start super()
        end

        def on_success(result)
          @end_time = Time.now
          stats.increment :succeeded
          debug_var :result, result
          super result
          monitor_success result
        end

        def on_rpc_response(result)
          rpc_result = super
          stats.increment :responded if rpc_result
          monitor_rpc_response result, rpc_result
        end

        def on_failure(exception)
          @end_time = Time.now
          stats.increment :failed
          monitor_failure exception, super(exception)
        end

        def on_end
          @finished_at = Time.now
        end

        private

        def monitor_start(start_result)
          debug "Event ##{short_id} started"
          debug_var :start_result, start_result
        end

        def monitor_success(result)
          info "Event ##{short_id} succeeded  in #{time_taken_str} with #{result.class.name}\n" +
                 "  #{result.inspect}"
        end

        def monitor_rpc_response(result, rpc_result)
          rpc = Array(rpc_result).flatten
          case rpc[0]
            when nil
              debug 'no rpc properties found, did not respond ...'
            when :responded
              debug "published result to [#{rpc[1]}] with ##{rpc[2]}: (#{result.class.name})" +
                      "#{result.inspect}"
          end
        end

        def monitor_failure(exception, failure_result)
          error "Event ##{short_id} failed with #{exception.class.name} : #{exception.message}\n" +
                  "  #{exception.backtrace[0, 5].join("\n  ")}\n in #{time_taken_str}"
          result = Array(failure_result).flatten
          case result[0]
            when :backoff
              info "Event ##{short_id} will be reran in #{result[1]} ms ..."
            when :dlq
              info "Event ##{short_id} was sent to #{result[1]} DLQ topic ..."
            when :finished
              info "Event ##{short_id} was finished ..."
          end
        end

        def time_taken
          return nil unless @end_time

          @end_time - @start_time
        end

        def time_taken_str
          Tiki::Torch::Utils.time_taken @start_time, @end_time
        end

      end
    end
  end
end
