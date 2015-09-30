module Tiki
  module Torch
    class YamlTranscoder < Transcoder

      class << self

        def code
          'yaml'
        end

        def encode(payload = {}, properties = {})
          { payload: payload, properties: properties }.to_yaml
        end

        def decode(str)
          hsh = YAML.load str
          [hsh[:payload], hsh[:properties]]
        end

      end

    end
  end
end
