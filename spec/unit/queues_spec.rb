module Tiki
  module Torch
    describe ChannelQueueWithTimeout do
      context 'multiple threads' do
        let(:qty) { 10 }
        let!(:queue) { described_class.new }
        let!(:list) { Concurrent::Array.new }
        let(:results) { qty.times.map { |x| x } }
        it 'can push and pop safely' do
          puts 'starting to write and read ...'
          [
            Thread.new { qty.times { |n| queue << n } },
            Thread.new { qty.times { list << queue.pop } },
          ].map { |x| x.join }
          puts 'done writing and reading ...'
          puts "list (#{list.class.name}) #{list.inspect}"
          puts "results (#{results.class.name}) #{results.inspect}"
          expect(list.sort).to eq results
        end
      end
    end
  end
end
