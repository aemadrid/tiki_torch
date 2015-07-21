module Tiki
  module Torch
    describe Logging do
      context 'logger' do
        context 'should have the same logger' do
          it 'on Torch and consumer' do
            expect(Torch.logger).to eq SimpleConsumer.logger
          end
          it 'on consumer and another consumer' do
            expect(SleepyConsumer.logger).to eq SimpleConsumer.logger
          end
        end
      end
    end
  end
end
