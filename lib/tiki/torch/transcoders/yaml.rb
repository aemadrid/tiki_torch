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
          if RUBY_VERSION[0].to_i < 3
            YAML.load(str)
          else
            YAML.load(str, permitted_classes: Torch.config.permitted_classes_for_YAML)
          end
        end
      end
    end
  end
end
