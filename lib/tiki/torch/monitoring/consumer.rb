module Tiki
  module Torch
    module Monitoring

      STAT_KEYS = [:published, :pop, :received, :success, :failure].freeze

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

          def store_stat(action, qty = 1, time = Time.now)
            key = stats_key(action)
            debug "storing | %-30.30s : %2i : %s" % [key, qty, time]
            Monitoring.store.store key, { count: qty }, time
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

          def failed_since?(time_ago)
            count_since(:failure, time_ago) > 0
          end

          def stats_key(action)
            "#{action}:#{monitor_name}"
          end

          # Return the latest counts in minute increments
          def stats(*times)
            Array(times).flatten.each_with_object({}) do |min, hsh|
              hsh[min] = Monitoring::STAT_KEYS.each_with_object({}) do |key, res|
                res[key] = count_since key, min.minutes.ago
              end
            end
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