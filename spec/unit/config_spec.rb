module Tiki
  module Torch
    describe Config do
      context 'default' do
        before(:context) { TestingHelpers.config_torch }
        subject { ::Tiki::Torch.config }
        context 'values' do
          it('access_key_id           ') { expect(subject.access_key_id).to eq ENV.fetch('AWS_TEST_ACCESS_KEY_ID', 'fake_access_key') }
          it('secret_access_key       ') { expect(subject.secret_access_key).to eq ENV.fetch('AWS_TEST_SECRET_ACCESS_KEY', 'fake_secret_key') }
          it('region                  ') { expect(subject.region).to eq ENV.fetch('AWS_TEST_REGION', 'fake_region') }

          it('sqs_endpoint            ') { expect(subject.sqs_endpoint).to eq "http://#{$fake_sqs.options[:sqs_endpoint]}:#{$fake_sqs.options[:sqs_port]}" }
          it('session_token           ') { expect(subject.session_token).to be_nil }

          it('topic_prefix            ') { expect(subject.topic_prefix).to eq 'tiki_torch' }
          it('dlq_postfix             ') { expect(subject.dlq_postfix).to eq 'dlq' }
          it('channel                 ') { expect(subject.channel).to eq 'events' }
          it('visibility_timeout      ') { expect(subject.visibility_timeout).to eq 600 }
          it('message_retention_period') { expect(subject.message_retention_period).to eq 345600 }

          it('max_in_flight           ') { expect(subject.max_in_flight).to eq 10 }
          it('max_attempts            ') { expect(subject.max_attempts).to eq 10 }

          it('event_pool_size         ') { expect(subject.event_pool_size).to eq Concurrent.processor_count }
          it('transcoder_code         ') { expect(subject.transcoder_code).to eq 'yaml' }
          it('events_sleep_times      ') { expect(subject.events_sleep_times).to eq({ idle: 1, busy: 0.1, received: 0.1, empty: 0.5, exception: 0.5 }) }
        end
        context 'configure block' do
          it 'changes values' do
            old_value = subject.max_in_flight
            ::Tiki::Torch.configure do |config|
              config.max_in_flight = 500
            end
            expect(subject.max_in_flight).to eq 500
            subject.max_in_flight = old_value
          end
        end
      end
      context 'custom' do
        let(:params) { {} }
        subject { ::Tiki::Torch::Config.new params }
        context 'direct access' do
          it 'changes values' do
            subject.max_in_flight = 500
            expect(subject.max_in_flight).to eq 500
          end
        end
        context 'mass assignment' do
          let(:params) { { max_in_flight: 500 } }
          it 'changes values' do
            expect(subject.max_in_flight).to eq 500
          end
        end
      end
    end
  end
end
