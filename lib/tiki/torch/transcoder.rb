module Tiki
  module Torch
    class Transcoder

      class << self

        def inherited(subclass)
          unless registry.include? subclass
            registry << subclass
          end
        end

        def registry
          @registry ||= []
        end

        def transcoder_for(code)
          registry.find { |klass| klass.code == code.to_s }
        end

        def encode(payload = {}, properties = {}, code = 'yaml')
          transcoder = transcoder_for(code)
          raise "Unknown transcoder code [#{code}]" unless transcoder

          "#{code}|#{transcoder.encode(payload, properties)}"
        end

        def decode(str)
          code, body = split_encoding str
          raise "Invalid encoding [#{code}]" unless code

          transcoder = transcoder_for code
          raise "Unknown encoding [#{code}]" unless transcoder

          transcoder.decode body
        end

        private

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
