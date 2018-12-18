#frozen_string_literal: true
module Tiki
  module Torch
    module Publishing
      class Message

        attr_reader :serialization_strategy, :format,  :properties, :payload

        alias :code :format

        def initialize(payload, properties = {}, format = nil, serialization_strategy = nil)
          @payload = payload
          @properties = properties
          @format = format ? validate_format!(format) : Torch.config.transcoder_code
          @serialization_strategy = serialization_strategy || Torch.config.serialization_strategy
        end

        def serialize
          case serialization_strategy
          when Torch::Config::SerializationStrategies::PREFIX
            serialize_with_inline_properties
          when Torch::Config::SerializationStrategies::MESSAGE_ATTRIBUTES
            serialize_with_attributes
          else
            serialize_with_inline_properties
          end
        end

        private

        def valid_formats
          Torch.config.valid_formats
        end

        def serialize_with_inline_properties
          Torch::Serialization::PrefixStrategy.serialize(self)
        end

        def serialize_with_attributes
          Torch::Serialization::AttributesStrategy.serialize(self)
        end

        def validate_format!(format)
          fail ArgumentError, "#{format} is not a valid format option" unless valid_formats.include?(format)
          format
        end

      end
    end
  end
end
