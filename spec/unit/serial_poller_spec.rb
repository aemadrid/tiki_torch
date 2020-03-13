# frozen_string_literal: true

module Tiki
  module Torch
    describe SerialPoller, :fast do
      let(:consumer) { SimpleConsumer }
      let(:client) { instance_double 'Tiki::Torch::AwsClient', queue: queue, to_s: '#<T:T:AwsClient>' }
      let(:queue) { instance_double 'Tiki::Torch::AwsQueue', attributes: queue_attrs, receive_messages: messages }
      let(:queue_attrs) { {} }
      let(:messages) { [] }
      subject { described_class.new consumer, client }
      context 'basic' do
        it('to_s') { expect(subject.to_s).to eq %(#<T:T:SerialPoller consumer="SimpleConsumer">) }
        it('serial_qty') { expect(Torch.config.serial_qty).to eq 10 }
        it('serial_timeout') { expect(Torch.config.serial_timeout).to eq 1 }
        it('serial_visibility') { expect(Torch.config.serial_visibility).to eq 60 }
      end
      context '#run_once' do
        let(:result) { subject.run_once }
        context 'on empty' do
          before { expect(queue).to_not receive(:receive_messages) }
          it('does not try to poll') { expect(result).to eq false }
        end
        context 'with messages' do
          let(:queue_attrs) { { 'ApproximateNumberOfMessages' => 1 } }
          let(:body) { "yaml|---\n:payload: hello!\n:properties: {}\n" }
          let(:attributes) { { 'first' => values.call({ string_value: 'bar', data_type: 'String' }) } }
          let(:values) { ->(hsh) { OpenStruct.new(hsh) } }
          let(:message) do
            instance_double 'Tiki::Torch::AwsMessage',
                            short_id: 'abc123',
                            body: body,
                            message_attributes: attributes,
                            delete: true
          end
          before { $lines = TestingHelpers::LogLines.new }
          context 'on success' do
            let(:messages) { [message, message, message] }
            it('polls and processes') { expect(result).to eq 3 }
          end
          context 'on failure' do
            let(:messages) { [message] }
            let(:error) { RuntimeError.new 'oh oh' }
            before { expect_any_instance_of(consumer).to receive(:process).and_raise(error) }
            it('polls and processes') { expect(result).to eq 0 }
          end
        end
      end
    end
  end
end
