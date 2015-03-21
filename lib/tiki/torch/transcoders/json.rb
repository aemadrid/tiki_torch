require 'multi_json'

module Tiki
  module Torch
    class JsonTranscoder < Transcoder

      class << self

        def code
          'json'
        end

        def encode(payload = {}, properties = {})
          MultiJson.dump payload:    payload,
                         properties: properties
        end

        def decode(str)
          hsh = MultiJson.load str, symbolize_keys: true
          [hsh[:payload], hsh[:properties]]
        end

      end

    end
  end
end
