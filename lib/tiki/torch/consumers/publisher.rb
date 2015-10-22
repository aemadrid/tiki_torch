module Tiki
  module Torch
    class Consumer
      module Publishing

        def publish(queue_name, payload, properties = {})
          defaults = Torch.config.default_message_properties
          custom   = { parent_message_id: event.message_id }.merge properties.dup
          Torch.publish queue_name, payload, defaults.merge(custom)
        end

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods

          def publish(payload, properties = {})
            defaults = Torch.config.default_message_properties
            debug "queue_name : #{queue_name}"
            Torch.publish queue_name, payload, defaults.merge(properties.dup)
          end

        end

      end
    end
  end
end
