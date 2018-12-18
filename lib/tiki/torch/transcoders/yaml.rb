module Tiki
  module Torch
    class YamlTranscoder < Transcoder

      class << self

        def codes
          Torch::Config::YAML_CODES
        end

        def encode(body = {})
          body.to_yaml
        end

        def decode(str)
          YAML.load(str)
        end

      end

    end
  end
end
