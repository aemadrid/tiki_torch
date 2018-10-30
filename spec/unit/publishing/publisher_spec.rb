module Tiki
  module Torch
    module Publishing
      describe Publisher, :fast do

        let(:topic_name){ "cheese" }
        let(:payload) { {cheese: {type: "swiss"}} }
        let(:props) { {texture: "holey", prefix: "fantastic"} }
        let(:subject) { Publisher.new }
        let(:mock_queue) { Torch::AwsQueue.new("x","y","z").tap {|q| allow(q).to receive(:send_message).and_return(true)} }

        describe "#publish" do
          context "yaml with prefix serialization" do
            let(:event) { Event.new(payload, props, "yaml") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with("fantastic-cheese-events").and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(/\Ayaml|/)
              subject.publish("cheese", event)
            end
          end

          context "json with prefix serialization" do
            let(:event) { Event.new(payload, props, "json") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with("fantastic-cheese-events").and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(/\Ajson|/)
              subject.publish("cheese", event)
            end
          end

          context "yaml with attribute serialization" do
            let(:event) { Event.new(payload, props, "yaml", "message_attributes") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with("fantastic-cheese-events").and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(instance_of(Hash))
              subject.publish("cheese", event)
            end
          end

          context "json with attribute serialization" do
            let(:event) { Event.new(payload, props, "json", "message_attributes") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with("fantastic-cheese-events").and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(instance_of(Hash))
              subject.publish("cheese", event)
            end
          end

        end
      end
    end
  end

  describe Torch do

    # This is testing a bit of implementation, but 
    describe "self.publish" do
      before {
        allow(Torch).to receive(:manager).and_return(
          double("manager",publisher: double("publisher", publish: true))
        )
      }
      it "builds an event with the default strategy" do
        expect(Torch::Publishing::Event).to receive(:new).with("a",{},"yaml","prefix")
        Torch.publish("topic", "a", {})
      end
    end
  end
end
