# frozen_string_literal: true

require 'integration/compatibility/helpers'

describe 'message processing', :fast do
  let(:data) { OpenStruct.new({ body: body, message_attributes: attributes, message_id: '1234567890' }) }
  let(:message) { Tiki::Torch::AwsMessage.new(data, double('queue', client: double('client'), url: '/foo', name: 'name')) }

  subject { TestBroker.new(TestConsumer, double('Manager')) }
  before do
    subject.event_pool = FakeEventPool
  end

  context 'given message attributes' do
    let(:attributes) do
      {
        'Content-Type' => Aws::SQS::Types::MessageAttributeValue.new({ string_value: format, data_type: 'String' }),
        'Color' => Aws::SQS::Types::MessageAttributeValue.new({ string_value: 'yellow', data_type: 'String' })
      }
    end

    context 'and a json format' do
      let(:format) { 'json' }
      let(:body) { '{"foo":{"bar":"buzz"}}' }

      it 'the event should deserialize correctly' do
        subject.send(:process_message, message)

        expect(TestQueue.pop).to eq({ foo: { bar: 'buzz' } })
      end
    end

    context 'and a yaml format' do
      let(:format) { 'yaml' }
      let(:body) { "---\n:foo:\n    :bar: buzz" }

      it 'the event should deserialize correctly' do
        subject.send(:process_message, message)

        expect(TestQueue.pop).to eq({ foo: { bar: 'buzz' } })
      end
    end
  end

  context 'with no message attributes' do
    let(:attributes) { {} }
    let(:data) { OpenStruct.new({ body: body, message_attributes: attributes, message_id: '1234567890' }) }

    context 'and a json prefix' do
      let(:format) { 'json' }
      let(:body) { 'json|{"payload": {"foo":{"bar":"buzz"}}}' }

      it 'the event should deserialize correctly' do
        subject.send(:process_message, message)

        expect(TestQueue.pop).to eq({ foo: { bar: 'buzz' } })
      end
    end

    context 'and a yaml format' do
      let(:format) { 'yaml' }
      let(:body) { "yaml|---\n:payload:\n  :foo:\n    :bar: buzz\n:properties:\n  :color: yellow" }

      it 'the event should deserialize correctly' do
        subject.send(:process_message, message)

        expect(TestQueue.pop).to eq({ foo: { bar: 'buzz' } })
      end
    end

    context 'invalid encoding' do
      let(:body) { "spam|---\n:payload:\n  :foo:\n    :bar: buzz\n:properties:\n  :color: yellow" }

      it 'causes an error' do
        expect { subject.send(:process_message, message) }.to raise_error('Invalid encoding [spam]')
      end
    end
  end
end
