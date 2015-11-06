module Tiki
  module Torch
    module Monitoring
      module Reporting

        extend self

        def latest_for_action(action, type, qty, queue_name = nil)
          key = "#{action}"
          key += ":#{Utils.simplified_name(queue_name)}" if queue_name
          res = Monitoring.store.find(key, qty.send(type).ago, Time.now).total
          res[:count] || 0
        end

      end
    end
  end
end