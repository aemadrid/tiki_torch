module Tiki
  module Torch
    module Publishing
      describe Publisher, :fast do

        let(:topic_name){ "cheese" }
        let(:full_topic_name){ "fantastic-cheese-events" }
        let(:payload) { {cheese: {type: "swiss"}} }
        let(:props) { {texture: "holey", prefix: "fantastic"} }
        let(:subject) { Publisher.new }
        let(:mock_queue) { Torch::AwsQueue.new("x","y","z").tap {|q| allow(q).to receive(:send_message).and_return(true)} }

        describe "#publish" do
          context "yaml with prefix serialization" do
            let(:event) { Message.new(payload, props, "yaml") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with(full_topic_name).and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(/\Ayaml|/)
              subject.publish(topic_name, event)
            end
          end

          context "json with prefix serialization" do
            let(:event) { Message.new(payload, props, "json") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with(full_topic_name).and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(/\Ajson|/)
              subject.publish(topic_name, event)
            end
          end

          context "yaml with attribute serialization" do
            let(:event) { Message.new(payload, props, "yaml", "message_attributes") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with(full_topic_name).and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(instance_of(Hash))
              subject.publish(topic_name, event)
            end
          end

          context "json with attribute serialization" do
            let(:event) { Message.new(payload, props, "json", "message_attributes") }
            it "sends a message" do
              expect(Torch.client).to receive(:queue).with(full_topic_name).and_return(mock_queue)
              expect(mock_queue).to receive(:send_message).with(instance_of(Hash))
              subject.publish(topic_name, event)
            end
          end

          context "with an exception raised" do
            let(:msg) { Message.new(payload, props, "json", "message_attributes") }
            let(:error) { StandardError.new "test error" }

            before do
              allow(Torch.client).to receive(:queue).with(full_topic_name).and_return(mock_queue)
              allow(mock_queue).to receive(:send_message).and_raise(error)
            end

            context "with no error handler configured" do
              it "should silently ignore the exception" do
                expect(subject).to receive(:log_exception)
                expect { subject.publish(topic_name, msg) }.to_not raise_error
              end
            end

            context "with an error handler configured" do
              let(:handler) { Proc.new { |e, _tpc, _evt| raise e } }

              before do
                allow(Torch.config).to receive(:publishing_error_handler).and_return(handler)
                expect(handler).to receive(:call).with(error, topic_name, msg).and_call_original
              end

              it "should log and re-raise the error" do
                expect(subject).to receive(:log_exception)
                expect { subject.publish(topic_name, msg) }.to raise_error(error)
              end
            end
          end
        end
      end
    end
  end
end

