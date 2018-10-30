module Tiki
  module Torch
    describe Config, :fast do
      subject { Torch.config }
      context 'basic' do
        it('to_s') { expect(subject.to_s).to eq %{#<T:T:Config access_key_id="#{TEST_ACCESS_KEY_ID}" region="#{TEST_REGION}">} }
      end
      context 'default' do
        before(:context) { TestingHelpers.config_torch }
        context 'values' do
          it('access_key_id     ')     { expect(subject.access_key_id).to eq TEST_ACCESS_KEY_ID }
          it('secret_access_key ')     { expect(subject.secret_access_key).to eq TEST_SECRET_ACCESS_KEY }
          it('region            ')     { expect(subject.region).to eq TEST_REGION }

          it('prefix            ')     { expect(subject.prefix).to eq TEST_PREFIX }
          it('channel           ')     { expect(subject.channel).to eq 'events' }

          it('default_delay     ')     { expect(subject.default_delay).to eq 0 }
          it('max_size          ')     { expect(subject.max_size).to eq 262144 }
          it('retention_period  ')     { expect(subject.retention_period).to eq 345600 }
          it('policy            ')     { expect(subject.policy).to be_nil }
          it('receive_delay     ')     { expect(subject.receive_delay).to eq 0 }
          it('visibility_timeout')     { expect(subject.visibility_timeout).to eq 60 }

          it('use_dlq           ')     { expect(subject.use_dlq).to be_falsey }
          it('dlq_postfix       ')     { expect(subject.dlq_postfix).to eq 'dlq' }
          it('max_attempts      ')     { expect(subject.max_attempts).to eq 10 }

          it('event_pool_size   ')     { expect(subject.event_pool_size).to eq Concurrent.processor_count }
          it('transcoder_code   ')     { expect(subject.transcoder_code).to eq 'yaml' }
          it('events_sleep_times')     { expect(subject.events_sleep_times).to eq(TEST_EVENT_SLEEP_TIMES) }
          it('serialization_strategy') { expect(subject.serialization_strategy).to eq(Config::SerializationStrategies::PREFIX) }

          context 'fake', on_fake_sqs: true do
            it('sqs_endpoint   ') { expect(subject.sqs_endpoint).to eq FAKE_SQS_ENDPOINT }
          end
        end
        context 'configure block' do
          it 'changes values' do
            old_value = subject.max_attempts
            ::Tiki::Torch.configure do |config|
              config.max_attempts = 500
            end
            expect(subject.max_attempts).to eq 500
            subject.max_attempts = old_value
          end
        end
      end
      context 'custom' do
        let(:params) { {} }
        subject { ::Tiki::Torch::Config.new params }
        context 'direct access' do
          it 'changes values' do
            subject.max_attempts = 500
            expect(subject.max_attempts).to eq 500
          end
        end
        context 'mass assignment' do
          let(:params) { { max_attempts: 500 } }
          it 'changes values' do
            expect(subject.max_attempts).to eq 500
          end
        end
      end
    end
  end
end
