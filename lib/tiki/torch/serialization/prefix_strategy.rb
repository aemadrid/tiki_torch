module Tiki
  module Torch
    module Serialization
      class PrefixStrategy

        class << self

          def serialize(event)
            properties = build_properties(event.properties)
            body = { payload: event.payload, properties: properties }
            res = Torch::Transcoder.encode(body, event.code)
            "#{event.code}|#{res}"
          end

          def deserialize(event)
            body = event.body.dup
            code, body = split_encoding(body)
            res = Torch::Transcoder.decode(body, code)
            [res[:payload], res[:properties]]
          end

          private

          def build_properties(properties)
            Torch.config.default_message_properties.dup
              .merge(message_id: SecureRandom.hex, published_at: Time.now)
              .merge(properties)
          end

          def split_encoding(str)
            sig = str[0, 255]
            len = sig.index('|')
            if len > 0
              sig, body = str[0, len], str[len+1 .. -1]
            else
              sig, body = nil, nil
            end
            [sig, body]
          end

        end
      end
    end
  end
end
