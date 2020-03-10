# frozen_string_literal: true

module Tiki
  module Torch
    module Consumers
      describe Event, :fast do
        let(:body) { "yaml|---\n:payload: hello!\n:properties: {}\n" }
        let(:attributes) { { 'first' => values.call({ string_value: 'bar', data_type: 'String' }) } }
        let(:values) { ->(hsh) { OpenStruct.new(hsh) } }
        let(:message) { instance_double 'Tiki::Torch::AwsMessage', short_id: 'abc123', body: body, message_attributes: attributes }
        subject { described_class.new message }

        context 'basic' do
          it('to_s') { expect(subject.to_s).to eq '#<T:T:C:Event short_id="abc123", body=42, payload="String">' }
        end

        describe 'deserialization' do
          context 'with content_type attribute' do
            let(:attributes) { { 'Content-Type' => values.call({ string_value: 'json', data_type: 'String' }) } }
            let(:body) { '{"foo":{"bar":"baz"}}' }

            it 'decodes according to content type' do
              expect(subject.payload).to eq({ foo: { bar: 'baz' } })
            end
          end

          context 'without content_type attribute' do
            let(:attributes) { {} }
            let(:body) { "yaml|---\n:payload:\n  foo:\n    bar: baz\n:properties: {}\n" }

            it 'decodes according to default settings' do
              expect(subject.payload).to eq({ 'foo' => { 'bar' => 'baz' } })
            end
          end
        end
      end
    end
  end
end
