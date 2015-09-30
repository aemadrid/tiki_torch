module Tiki
  module Torch
    describe ChannelQueueWithTimeout do
      context 'multiple threads' do
        let!(:queue) { described_class.new }
        let!(:list) { Concurrent::Array.new }
        let(:results) { [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] }
        it 'can push and pop safely' do
          [
            Thread.new { (0..4).each { |n| queue << n } },
            Thread.new { 5.times { list << queue.pop } },
            Thread.new { (5..9).each { |n| queue << n } },
            Thread.new { 5.times { list << queue.pop } },
          ].map { |x| x.join }
          expect(list.sort).to eq results
          expect { queue.pop }.to raise_error Timeout::Error
        end
      end
    end
  end
end
