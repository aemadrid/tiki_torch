module Tiki
  module Torch
    module Monitoring
      module Consumer

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods

          def pop_results(req_size, found_size, timeout)
            super
            store_stat :pop
            store_stat :received, found_size if found_size > 0
          end

          def store_stat(action, qty = 1)
            key = stats_key(action)
            Monitoring.store.store key, count: qty
          rescue StandardError => e
            error "on_#{action} | Exception : #{e.class.name} : #{e.message}"
          end

          def count_since(action, time_ago)
            res = Monitoring.store.find(stats_key(action), time_ago, Time.now + 1).total
            res ? res.fetch(:count, 0) : 0
          end

          def published_since?(time_ago)
            count_since(:published, time_ago) > 0
          end

          def stats_key(action)
            "#{action}:#{Utils.simplified_name(queue_name)}"
          end

        end

        def on_success(result)
          super
          self.class.store_stat :success
        end

        def on_failure(exception)
          super
          self.class.store_stat :failure
        end

      end
    end

    class Consumer
      include Monitoring::Consumer
    end
  end
end