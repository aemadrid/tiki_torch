# frozen_string_literal: true

module Tiki
  module Torch
    describe Logging, :fast do
      let(:consumer) { ExceptionalConsumer }
      let(:logger) { Torch.logger }
      context 'logger' do
        context 'should have the same logger' do
          it 'on Torch and consumer' do
            expect(logger).to eq consumer.logger
          end
        end
      end
      context 'instance' do
        subject { consumer.new nil, nil }
        let(:message) { 'Hey!' }
        let(:message_rx) { /#{message}/ }
        context 'debug_var' do
          before { expect(logger).to receive(:debug).with(message_rx) }
          it { subject.debug_var :message, message }
        end
        context 'debug' do
          before { expect(logger).to receive(:debug).with(message_rx) }
          it { subject.debug message }
        end
        context 'info' do
          before { expect(logger).to receive(:info).with(message_rx) }
          it { subject.info message }
        end
        context 'warn' do
          before { expect(logger).to receive(:warn).with(message_rx) }
          it { subject.warn message }
        end
        context 'error' do
          before { expect(logger).to receive(:error).with(message_rx) }
          it { subject.error message }
        end
        context 'log_exception' do
          let(:error) { RuntimeError.new 'oh oh' }
          context 'when raising errors' do
            before do
              consumer.raise_errors = true
              expect(logger).to_not receive(:error).with(/Exception:/)
            end
            it do
              expect(consumer.raise_errors?).to eq true
              expect { subject.process }.to raise_error(RuntimeError, 'oh oh')
            end
          end
          context 'when not raising errors' do
            before do
              consumer.raise_errors = false
              expect(logger).to receive(:error).with(/Exception:/)
            end
            it do
              expect(consumer.raise_errors?).to eq false
              expect { subject.process }.to_not raise_error
            end
          end
          context 'with an exception proc' do
            before do
              consumer.raise_errors = false
              consumer.on_exception do |e, extras|
                ExceptionalConsumer.error "on_exception : #{e.class.name} : #{extras.inspect}"
              end
              expect(logger).to receive(:error).with(/Exception:/)
              expect(logger).to receive(:error).with(/on_exception : RuntimeError : {:weird=>"error"}/)
            end
            it { subject.process }
          end
          after do
            consumer.raise_errors = false
            consumer.on_exception :clear
          end
        end
      end
    end
  end
end
