# frozen_string_literal: true

module Tiki
  module Torch
    describe SerialManager, :fast do
      let(:consumer) { SimpleConsumer }
      let(:queue) { instance_double 'Tiki::Torch::AwsQueue' }
      let(:client) { instance_double 'Tiki::Torch::AwsClient', queue: queue }
      subject { described_class.new client }

      before do
        allow(ConsumerBuilder).to receive(:build).and_return true
        allow(ConsumerRegistry).to receive(:all).and_return [consumer]
        allow_any_instance_of(SerialPoller).to receive(:run_once) do
          @run_once_count ||= 0
          @run_once_count += 1
          true
        end
      end

      context 'basic' do
        it('to_s') { expect(subject.to_s).to eq %(#<T:T:SerialManager pollers=1>) }
        it('running?') { expect(subject.running?).to eq false }
        it('serial_wait_secs') { expect(Torch.config.serial_wait_secs).to eq 1.5 }
      end

      context 'polling' do
        context 'runs cycle' do
          it 'works' do
            thread = Thread.new { subject.start_polling }
            sleep 0.25
            expect(subject.running?).to eq true
            sleep 0.25 while @run_once_count < 3
            subject.stop_polling
            thread.join
            expect(@run_once_count).to eq 3
            expect(subject.running?).to eq false
          end
        end
      end
    end
  end
end
