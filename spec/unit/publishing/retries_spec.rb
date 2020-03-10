# frozen_string_literal: true

module Tiki
  module Torch
    module Publishing
      describe Retries, :fast do
        let(:topic_name) { 'cheese' }
        let(:full_topic_name) { 'fantastic-cheese-events' }
        let(:payload) { { cheese: { type: 'swiss' } } }
        let(:props) { { texture: 'holey', prefix: 'fantastic' } }
        let(:event) { Message.new payload, props, 'yaml' }
        let(:error) { StandardError.new 'some error' }
        let(:mock_queue) { Torch::AwsQueue.new('x', 'y', 'z') }
        let(:wait_time) { 1 }
        let(:publisher) { Publisher.new }

        before do
          allow(Torch.client).to receive(:queue).with(full_topic_name).and_return(mock_queue)
          # Fail the first two times to send a message
          allow(mock_queue).to receive(:send_message) do |_event|
            @cnt ||= 0
            @cnt += 1
            do_raise = @cnt < 3
            do_raise ? raise(StandardError, 'some error') : true
          end
        end

        after(:each) { described_class.disable }

        describe 'retries messages on a schedule' do
          before { described_class.setup interval_secs: wait_time }
          it 'works' do
            publisher.publish(topic_name, event)
            expect(described_class.entries.size).to eq 1
            sleep wait_time + 1
            expect(described_class.entries.size).to eq 0
          end
        end

        describe 'retries messages on a custom schedule' do
          let(:tries) { [] }
          before do
            described_class.setup interval_secs: wait_time,
                                  error_handler: proc { |_e, topic_name, event| described_class.add topic_name, event },
                                  retry_handler: proc { |_entries, entry| tries << entry.tries }
          end
          it 'works' do
            publisher.publish(topic_name, event)
            expect(described_class.entries.size).to eq 1
            sleep wait_time + 1
            expect(described_class.entries.size).to eq 0
            expect(tries).to eq [1, 2]
          end
        end
      end
    end
  end
end
