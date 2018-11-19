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
          registry.find { |klass| klass.codes.include?(code.to_s) }
        end

        def encode(body, code = 'yaml')
          transcoder = transcoder_for(code)
          raise "Unknown transcoder code [#{code}]" unless transcoder
          transcoder.encode(body)
        end

        def decode(str, code = 'yaml')
          transcoder = transcoder_for(code)
          raise "Invalid encoding [#{code}]" unless transcoder
          transcoder.decode str
        end

      end

    end
  end
end
