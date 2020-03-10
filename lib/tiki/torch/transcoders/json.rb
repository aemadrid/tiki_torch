module Tiki
  module Torch
    class JsonTranscoder < Transcoder

      class << self

        def codes
          Torch::Config::JSON_CODES
        end

        def encode(body = {})
          MultiJson.dump body
        end

        def decode(str)
          MultiJson.load(str, symbolize_keys: true)
        end

      end
    end
  end
end
