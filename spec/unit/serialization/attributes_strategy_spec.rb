module Tiki
  module Torch
    module Serialization
      describe AttributesStrategy, :fast do

        let(:event) { Publishing::Event.new(payload, properties, format, strategy) }
        let(:payload) { {foo: { bar: "buzz" }} }
        let(:properties) { {color: "yellow", purpose: "shenanigans", transcoder_code: format} }
        let(:strategy) { Torch::Config::SerializationStrategies::MESSAGE_ATTRIBUTES }

        describe "#serialize" do

          context "with a json transcoder" do
            let(:format) { "application/json" }

            it "properly serializes attributes" do
              event.serialize.tap do |e|
                e[:message_attributes].tap do |a|
                  expect(a["Content-Type"]).to eq({ string_value: format, data_type: "String"})
                  expect(a["color"]).to eq({ string_value: "yellow", data_type: "String"})
                  expect(a["purpose"]).to eq({ string_value: "shenanigans", data_type: "String"})
                  expect(a["transcoder_code"]).to be_nil
                end
              end
            end

            it "serializes the message body as json" do
              expect(event.serialize[:message_body]).to eq("{\"foo\":{\"bar\":\"buzz\"}}")
            end
          end

          context "with a yaml transcoder" do
            let(:format){ "application/x-yaml" }

            it "properly serializes attributes" do
              event.serialize.tap do |e|
                e[:message_attributes].tap do |a|
                  expect(a["Content-Type"]).to eq({ string_value: format, data_type: "String"})
                  expect(a["color"]).to eq({ string_value: "yellow", data_type: "String"})
                  expect(a["purpose"]).to eq({ string_value: "shenanigans", data_type: "String"})
                  expect(a["transcoder_code"]).to be_nil
                end
              end
            end

            it "serializes the message body as yaml" do
              expect(event.serialize[:message_body]).to eq("---\n:foo:\n  :bar: buzz\n")
            end
          end
        end

        describe "#deserialize" do

          # https://docs.aws.amazon.com/sdkforruby/api/Aws/SQS/Message.html

          let(:attributes) {
            {
              "Content-Type" => Aws::SQS::Types::MessageAttributeValue.new({string_value: format, data_type: "String"}),
              "Color" => Aws::SQS::Types::MessageAttributeValue.new({string_value: "yellow", data_type: "String"})
            }
          }
          let(:data) { OpenStruct.new({body: body, message_attributes: attributes}) }
          let(:message) { AwsMessage.new(data, double("queue", client: double("client"), url: "/foo", name: "name")) }
          let(:event) { Consumers::Event.new(message) }

          context "with a json transcoder" do
            let(:body) { "{\"foo\":{\"bar\":\"buzz\"}}" }
            let(:format) { "json" }

            it "uses content-type header to determine mime type" do
              expect(event.payload).to eq({foo: { bar: "buzz" }})
            end

            it "properly desrializes attributes" do
              expect(event.attributes).to eq({content_type: "json", color: "yellow"})
            end
          end

          context "with a yaml transcoder" do
            let(:body) { "---\n:foo:\n  :bar: buzz\n" }
            let(:format) { "yaml" }

            it "uses content-type header to determine mime type" do
              expect(event.payload).to eq({foo: { bar: "buzz" }})
            end

            it "properly desrializes attributes" do
              expect(event.attributes).to eq({content_type: "yaml", color: "yellow"})
            end
          end
        end

      end
    end
  end
end

