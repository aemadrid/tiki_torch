module Tiki
  module Torch
    describe ThreadPool, :fast do
      context 'states' do
        let!(:pool){ described_class.new :ready_pool, 3 }
        it 'on each step' do
          # Empty
          expect(pool.free?).to eq true
          expect(pool.ready?).to eq true
          expect(pool.busy?).to eq false

          # First job
          pool.async { sleep 0.5 }
          expect(pool.free?).to eq false
          expect(pool.ready?).to eq true
          expect(pool.busy?).to eq false

          # Second job
          pool.async { sleep 0.5 }
          expect(pool.free?).to eq false
          expect(pool.ready?).to eq true
          expect(pool.busy?).to eq false

          # Third job
          pool.async { sleep 0.5 }
          expect(pool.free?).to eq false
          expect(pool.ready?).to eq false
          expect(pool.busy?).to eq true

          # After being fully booked
          expect {
            pool.async { sleep 0.5 }
          }.to raise_error ThreadPool::NotReadyError, 'Not ready to run async jobs'
        end
      end
    end
  end
end
