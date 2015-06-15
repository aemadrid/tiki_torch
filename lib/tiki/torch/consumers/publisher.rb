module Tiki
  module Torch
    class Consumer
      module Publishing

        def publish(topic, payload, properties = {})
          Torch.publish topic, payload, default_message_properties.merge(properties.dup)
        end

        private

        def default_message_properties
          {
            parent_message_id: event.message_id,
          }
        end

      end
    end
  end
end
