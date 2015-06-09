module Tiki
  module Torch
    class Consumer

      # Stolen from https://github.com/moneydesktop/action_subscriber/blob/master/lib/action_subscriber/middleware/active_record/connection_management.rb

      module ArConnectionManagement
        def on_end
          super

          ::ActiveRecord::Base.clear_active_connections!
        end
      end

      # Stolen from https://github.com/moneydesktop/action_subscriber/blob/master/lib/action_subscriber/middleware/active_record/query_cache.rb

      module ArQueryCache
        def on_start
          super

          @ar_qc_enabled       = ::ActiveRecord::Base.connection.query_cache_enabled
          @ar_qc_connection_id = ::ActiveRecord::Base.connection_id
          ::ActiveRecord::Base.connection.enable_query_cache!
        end

        def on_end
          super

          ::ActiveRecord::Base.connection_id = @ar_qc_connection_id
          ::ActiveRecord::Base.connection.clear_query_cache
          ::ActiveRecord::Base.connection.disable_query_cache! unless @ar_qc_enabled
        end
      end
    end
  end
end
