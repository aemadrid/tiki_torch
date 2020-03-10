module Tiki
  module Torch
    class Consumer
      module Publishing

        def publish(queue_name, payload, properties = {}, format = Torch.config.transcoder_code )
          custom = { parent_message_id: event.message_id }.merge properties.dup
          message = Torch::Publishing::Message.new(payload, custom, format, config.serialization_strategy)
          Torch.publish_message(queue_name, message)
        end

        def publish_message(queue_name, message)
          Torch.publish_message(queue_name, message)
        end

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods

          def publish(payload, properties = {}, format = Torch.config.transcoder_code)
            props = Torch.config.default_message_properties.merge(properties.dup)
            debug "queue_name : #{queue_name}"
            message = Torch::Publishing::Message.new(payload, props, format, config.serialization_strategy)
            Torch.publish_message(queue_name, message)
          end

          def publish_message(event)
            Torch.publish_message(queue_name, message)
          end

        end
      end
    end
  end
end
