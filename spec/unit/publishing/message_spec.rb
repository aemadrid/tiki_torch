module Tiki
  module Torch
    module Publishing
      describe Message, :fast do

        it "uses defaults" do
          event = Message.new("foo", {})
          expect(event.format).to eq("yaml")
          expect(event.serialization_strategy).to eq(Torch.config.serialization_strategy)
        end

        it "validates provided formats" do
          expect{Message.new("foo", {}, "dumb")}.to raise_error(ArgumentError, "dumb is not a valid format option")
          expect(Message.new("foo", {}, "yaml").format).to eq("yaml")
        end

        describe "#serialize" do
          let(:body) { {foo: {bar: "baz"} } }
          let(:subject) { Message.new(body, {}, "json", strategy) }

          context "using prefix" do
            let(:strategy) { Torch::Config::SerializationStrategies::PREFIX }
            it "delegates to the proper serialization strategy" do
              expect(Torch::Serialization::PrefixStrategy).to receive(:serialize).with(subject)
              subject.serialize
            end
          end

          context "using attributes" do
            let(:strategy) { Torch::Config::SerializationStrategies::MESSAGE_ATTRIBUTES }
            it "delegates to the proper serialization strategy" do
              expect(Torch::Serialization::AttributesStrategy).to receive(:serialize).with(subject)
              subject.serialize
            end
          end

          context "defaults" do
            let(:subject) { Message.new(body, {}) }
            example "to prefix" do
              expect(Torch::Serialization::PrefixStrategy).to receive(:serialize).with(subject)
              subject.serialize
            end
          end
        end

        describe '#fingerprint' do
          let(:body) { {foo: {bar: "baz"} } }
          let(:subject) { Message.new(body, {}, "json") }

          it "provides a simple CRC fingerprint" do
            expect(subject.fingerprint).to eq 2757912629
          end
        end
      end
    end
  end
end
