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
            let(:event) { Message.new(payload, props, "yaml") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with("fantastic-cheese-events").and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(/\Ayaml|/)
              subject.publish("cheese", event)
            end
          end

          context "json with prefix serialization" do
            let(:event) { Message.new(payload, props, "json") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with("fantastic-cheese-events").and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(/\Ajson|/)
              subject.publish("cheese", event)
            end
          end

          context "yaml with attribute serialization" do
            let(:event) { Message.new(payload, props, "yaml", "message_attributes") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with("fantastic-cheese-events").and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(instance_of(Hash))
              subject.publish("cheese", event)
            end
          end

          context "json with attribute serialization" do
            let(:event) { Message.new(payload, props, "json", "message_attributes") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with("fantastic-cheese-events").and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(instance_of(Hash))
              subject.publish("cheese", event)
            end
          end

          context "with a StandardError raised" do
            let(:event) { Message.new(payload, props, "json", "message_attributes") }
            before do
              allow(Torch.client).to receive(:queue).with("fantastic-cheese-events").and_return(mock_queue)
              allow(mock_queue).to receive(:send_message).and_raise(StandardError, "test error")
            end

            it "should log and re-raise a PublishingError" do
              expect(subject).to receive(:log_exception)
              expect { subject.publish("cheese", event) }.to raise_error(described_class::PublishingError)
            end
          end

          context "with a low-level exception raised" do
            let(:event) { Message.new(payload, props, "json", "message_attributes") }
            before do
              allow(Torch.client).to receive(:queue).with("fantastic-cheese-events").and_return(mock_queue)
              allow(mock_queue).to receive(:send_message).and_raise(Exception, "test error")
            end

            it "should not swallow the exception" do
              expect { subject.publish("cheese", event) }.to raise_error(Exception)
            end
          end
        end
      end
    end
  end
end

