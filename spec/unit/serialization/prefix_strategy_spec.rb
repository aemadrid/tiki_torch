module Tiki
  module Torch
    module Serialization
      describe PrefixStrategy, :fast do

        let(:event) { Publishing::Message.new(payload, properties, format, strategy) }
        let(:payload) { {foo: { bar: "buzz" }} }
        let(:properties) { {color: "yellow", purpose: "shenanigans", transcoder_code: format} }
        let(:strategy) { Torch::Config::SerializationStrategies::PREFIX }

        describe "#serialize" do

          context "with a json transcoder" do
            let(:format) { "json" }

            it "properly serializes attributes" do
              e = event.serialize
              expect(e).to match(/\"color\":\"yellow\"/)
              expect(e).to match(/\"transcoder_code\":\"json\"/)
              expect(e).to match(/\"purpose\":\"shenanigans\"/)
            end

            it "prepends the transcoder type" do
              expect(event.serialize).to match(/\A#{format}|/)
            end
          end

          context "with a yaml transcoder" do
            let(:format){ "yaml" }

            it "properly serializes attributes" do
              e = event.serialize
              expect(e).to match(/:color: yellow/)
              expect(e).to match(/:transcoder_code: yaml/)
              expect(e).to match(/:purpose: shenanigans/)
            end

            it "prepends the transcoder type" do
              expect(event.serialize).to match(/\A#{format}|/)
            end
          end
        end

        describe "#deserialize" do
          let(:data) { OpenStruct.new({body: body}) }
          let(:message) { AwsMessage.new(data, double("queue", client: double("client"), url: "/foo", name: "name")) }
          let(:event) { Consumers::Event.new(message) }

          context "with json prefix" do
            let(:body) { "json|{\"payload\":{\"foo\":{\"bar\":\"buzz\"}},\"properties\":{\"color\":\"yellow\"}}" }
            it "chooses the correct transcoder" do
              expect(event.payload).to eq({foo: {bar: "buzz"}})
              expect(event.properties).to eq({color: "yellow"})
            end
          end

          context "with yaml prefix" do
            let(:body) { "yaml|---\n:payload:\n  :foo:\n    :bar: buzz\n:properties:\n  :color: yellow" }
            it "chooses the correct transcoder" do
              expect(event.payload).to eq({foo: {bar: "buzz"}})
              expect(event.properties).to eq({color: "yellow"})
            end
          end
        end
      end
    end
  end
end
