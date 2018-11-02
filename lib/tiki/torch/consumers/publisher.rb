module Tiki
  module Torch
    class Consumer
      module Publishing

        def publish(queue_name, payload, properties = {}, format = config.transcoder_code )
          custom = { parent_message_id: event.message_id }.merge properties.dup
          event = Torch::Publishing::Event.new(payload, custom, format, config.serialization_strategy)
          Torch.publish_event(queue_name, event)
        end

        def publish_event(queue_name, event)
          Torch.publish_event(queue_name, event)
        end

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods

          def publish(payload, properties = {}, format = config.transcoder_code)
            props = Torch.config.default_message_properties.merge(properties.dup)
            debug "queue_name : #{queue_name}"
            event = Torch::Publishing::Event.new(payload, props, format, config.serialization_strategy)
            Torch.publish_event(queue_name, event)
          end

          def publish_event(event)
            Torch.publish_event(queue_name, event)
          end

        end
      end
    end
  end
end
