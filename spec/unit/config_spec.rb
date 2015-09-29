module Tiki
  module Torch
    describe Config do
      context 'default' do
        subject { ::Tiki::Torch.config }
        context 'values' do
          it('topic_prefix            ') { expect(subject.topic_prefix).to eq 'tiki_torch-' }
          it('max_in_flight           ') { expect(subject.max_in_flight).to eq 10 }
          it('discovery_interval      ') { expect(subject.discovery_interval).to eq 60 }
          it('msg_timeout             ') { expect(subject.msg_timeout).to eq 5_000 }
          it('max_attempts            ') { expect(subject.max_attempts).to eq 100 }
          it('back_off_time_unit      ') { expect(subject.back_off_time_unit).to eq 3000 }
          it('transcoder_code         ') { expect(subject.transcoder_code).to eq 'yaml' }
          it('processor_count         ') { expect(subject.processor_count).to eq Concurrent.processor_count }
          it('event_pool_size         ') { expect(subject.event_pool_size).to eq Concurrent.processor_count }
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
