module Tiki
  module Torch
    module Consumers
      class Event

        extend Forwardable
        include Logging

        attr_reader :message

        def initialize(message)
          @message = message
          @deleted = false
        end

        delegate [:body, :delete, :message_attributes, :message_id, :short_id, :visibility_timeout=] => :message
        alias :id :message_id

        delegate [:[]] => :payload

        def payload
          deserialize_message unless @payload
          @payload
        end

        def attributes
          deserialize_message unless @attributes
          @attributes
        end

        def properties
          deserialize_message unless @properties
          @properties
        end

        def parent_message_id
          properties[:parent_message_id] || ' ' * 32
        end

        alias :parent_id :parent_message_id

        def parent_short_id
          parent_message_id[0, 3] + parent_message_id[-3, 3]
        end

        def message_attribute(attr)
          @message_attributes[attr]
        end

        def finished?
          !!@deleted
        end

        def finish
          return false if finished?

          debug "Finishing ##{short_id} ..."
          res      = message.delete
          @deleted = true
        end

        def to_s
          attrs = {
            short_id: short_id,
            body:     body.size,
            payload:  payload.class.name,
          }
          "#<T:T:C:Event #{attrs.map { |k, v| "#{k}=#{v.inspect}" }.join(', ')}>"
        end

        alias :inspect :to_s

        private

        def deserialize_message
          # content_type is expected to be a standard mime type; i.e. application/x-yaml, application/json
          content_type = message_attributes["Content-Type"]
          if content_type
            @payload, @attributes = Torch::Serialization::AttributesStrategy.deserialize(self)
          else
            @payload, @properties = Torch::Serialization::PrefixStrategy.deserialize(self)
          end
        end

        def parse_mime_type(mime_type)
          code = mime_type.split("/").last
          if code =~ /json/
            return "json"
          elsif code =~ /yaml/
            return "yaml"
          else
            return Torch.config.transcoder_code
          end
        end

      end
    end
  end
end
