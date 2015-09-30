module Tiki
  module Torch
    class QueueWithSleepTimeout

      def initialize
        @mutex = Mutex.new
        @queue = []
      end

      def push(x)
        @mutex.synchronize do
          @queue << x
        end
      end

      alias enq push
      alias << push

      def pop
        @mutex.synchronize { @queue.empty? ? nil : @queue.shift }
      end

      alias deq pop
      alias shift pop

      def pop_with_timeout(timeout = 0.5)
        deadline = Time.now + timeout
        found    = nil
        @mutex.synchronize do
          while Time.now < deadline && found.nil?
            if @queue.empty?
              sleep 0.1
            else
              found = @queue.shift
            end
          end
        end
        raise Timeout::Error, "Waited #{timeout} sec" if found.nil?
        found
      end

      def size
        @mutex.synchronize { @queue.size }
      end

      alias length size

      def empty?
        size == 0
      end

    end

    class ChannelQueueWithTimeout

      def initialize(max = 1_000)
        @queue = ::Concurrent::Channel.new size: max
      end

      def push(x)
        @queue << x
      end

      alias enq push
      alias << push

      def pop(timeout = 0.5)
        item = ::Concurrent::Channel.select do |s|
          s.take(@queue) { |msg| msg }
          s.after(timeout)
        end
        raise Timeout::Error, "Waited #{timeout}s" unless item
        item
      end

      alias deq pop
      alias shift pop
      alias pop_with_timeout pop

      def size
        @queue.size
      end

      alias length size

      def empty?
        size == 0
      end

    end
  end
end