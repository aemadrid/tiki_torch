module Tiki
  module Torch
    class Queue < Concurrent::Array

      alias native_push push

      def push(*args)
        native_push *args
      end

      alias enq push

      alias native_pop pop

      def pop(non_block = false)
        if non_block
          raise ThreadError if empty?
        else
          sleep 0.1 while empty?
        end
        shift
      end

      alias deq pop

    end
  end
end