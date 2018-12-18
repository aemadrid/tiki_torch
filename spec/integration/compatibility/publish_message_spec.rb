require 'integration/compatibility/helpers'
require 'integration/compatibility/shared_examples'

describe "publishing a message", :fast do

  before {
    allow(Tiki::Torch).to receive(:client).and_return(TestClient.new)
    allow(TestQueue).to receive(:is_a?).with(Tiki::Torch::AwsQueue).and_return(true)
    allow(TestQueue).to receive(:is_a?).with(Class).and_return(true)
  }

  after(:each) {
    # Restore defaults
    Tiki::Torch.configure do |c|
      c.serialization_strategy = "prefix"
      c.transcoder_code = "yaml"
    end
  }

  describe "#publish interface" do
    let(:payload) { {foo: { bar: "buzz" }} }
    let(:properties) { {color: "yellow", purpose: "shenanigans"} }
    let(:publish_message) { Tiki::Torch.publish('test_queue', payload, properties) }
    after(:each) {
      TestQueue.clear
    }

    # Prefix and Yaml are defaults
    context "with a prefix strategy" do
      context "and a yaml format" do
        it_behaves_like "a yaml message with prefix"
      end

      context "and a json format" do
        before {
          ::Tiki::Torch.configure do |c|
            c.transcoder_code = "json"
          end
        }
        it_behaves_like "a json message with prefix"
      end
    end

    context "with a message attributes strategy" do
      before {
        ::Tiki::Torch.configure do |c|
          c.serialization_strategy = Tiki::Torch::Config::SerializationStrategies::MESSAGE_ATTRIBUTES
        end
      }
      context "and a yaml format" do
        it_behaves_like "a yaml message with attributes"
      end

      context "and a json format" do
        before {
          ::Tiki::Torch.configure do |c|
            c.transcoder_code = "json"
          end
        }

        it_behaves_like "a json message with attributes"
      end
    end

  end

  describe "#publish_message interface" do
    let(:payload) { {foo: { bar: "buzz" }} }
    let(:properties) { {color: "yellow", purpose: "shenanigans"} }
    let(:event) { Tiki::Torch::Publishing::Message.new(payload, properties, format, strategy) }
    let(:publish_message) { Tiki::Torch.publish_message('test_queue', event) }
    after(:each) {
      TestQueue.clear
    }

    context "with msg attributes and json" do
      let(:format) { "json" }
      let(:strategy) { "message_attributes" }

      it_behaves_like "a json message with attributes"
    end

    context "with prefix and json" do
      let(:format) { "json" }
      let(:strategy) { "prefix" }
      it_behaves_like "a json message with prefix"
    end

    context "with msg attributes and yaml" do
      let(:format) { "yaml" }
      let(:strategy) { "message_attributes" }

      it_behaves_like "a yaml message with attributes"
    end

    context "with prefix and yaml" do
      let(:format) { "yaml" }
      let(:strategy) { "prefix" }
      it_behaves_like "a yaml message with prefix"
    end

  end

end
