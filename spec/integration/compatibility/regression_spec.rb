# frozen_string_literal: true

describe 'Compatibility' do
  describe SimpleConsumer, :integration do
    context 'using prefix message serialization strategy' do
      let(:message) { { foo: { bar: 'baz' } } }
      let(:properties) { { color: 'blue' } }
      let(:strategies) { Tiki::Torch::Config::SerializationStrategies }

      after(:each) do
        # This will mess up defaults later if left
        consumer.configure { |c| c.transcoder_code = 'yaml' }
      end
      context 'original publish interface' do
        context 'prefix serialization' do
          it 'publishes and consumes yaml successfully' do
            consumer.configure { |c| c.transcoder_code = 'yaml' }
            consumer.publish(message, properties)
            $lines.wait_for_size(1, 2)
            expect($lines.sorted).to include(message)
          end

          it 'publishes and consumes json successfully' do
            consumer.configure { |c| c.transcoder_code = 'json' }
            consumer.publish(message, properties)
            $lines.wait_for_size(1, 2)
            expect($lines.sorted).to include(message)
          end
        end
      end
    end
  end
end
