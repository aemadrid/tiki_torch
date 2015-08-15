module Tiki
  module Torch
    describe ThreadPool do
      context 'states' do
        let(:pool_size) { 5 }
        let(:pool) { described_class.new :ready_pool, pool_size }
        let(:sleep_time) { 0.5 }
        it 'on each step' do
          # Starting cold
          expect(pool.free?).to be_truthy
          expect(pool.ready?).to be_truthy
          expect(pool.busy?).to be_falsey
          # Adding one job at a time
          (1..pool_size).each do |nr|
            pool.async { sleep sleep_time }
            expect(pool.free?).to be_falsey
            expect(pool.ready?).to eq(nr < pool_size)
            expect(pool.busy?).to eq(nr == pool_size)
          end
          # After being fully booked
          expect { pool.async { sleep sleep_time } }.to raise_error(ThreadPool::NotReadyError, 'Not ready to run async jobs')
        end
      end
    end
  end
end
