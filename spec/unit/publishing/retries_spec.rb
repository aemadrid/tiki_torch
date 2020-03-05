module Tiki
  module Torch
    module Publishing
      describe Retries, :fast do

        let(:topic_name) { "cheese" }
        let(:full_topic_name) { "fantastic-cheese-events" }
        let(:payload) { { cheese: { type: "swiss" } } }
        let(:props) { { texture: "holey", prefix: "fantastic" } }
        let(:event) { Message.new payload, props, "yaml" }
        let(:error) { StandardError.new 'some error' }
        let(:mock_queue) { Torch::AwsQueue.new("x", "y", "z") }
        let(:wait_time) { 1 }
        let(:publisher) { Publisher.new }

        before do
          allow(Torch.client).to receive(:queue).with(full_topic_name).and_return(mock_queue)
          allow(mock_queue).to receive(:send_message) do |_event|
            @cnt ||= 0
            @cnt += 1
            raise StandardError.new("some error") if @cnt == 1
            true
          end
        end

        after { described_class.disable }

        describe "retries messages on a schedule" do
          before { described_class.setup wait_time }
          it 'works' do
            publisher.publish(topic_name, event)
            expect(described_class.entries.size).to eq 1
            sleep wait_time + 0.5
            expect(described_class.entries.size).to eq 0
          end
        end

        describe "retries messages on a custom schedule" do
          before do
            described_class.setup(wait_time) do |_e, topic_name, event|
              Tiki::Torch::Publishing::Retries.add topic_name, event
            end
          end
          it 'works' do
            publisher.publish(topic_name, event)
            expect(described_class.entries.size).to eq 1
            sleep wait_time + 0.5
            expect(described_class.entries.size).to eq 0
          end
        end
      end
    end
  end
end