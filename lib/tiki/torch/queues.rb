module Tiki
  module Torch
    class Queue < Concurrent::Array

      include Logging

      alias native_push push

      def push(*args)
        debug_var :args, args
        res = native_push *args
        debug_var :res, res
        res
      end

      alias enq push

      alias native_pop pop

      def pop(non_block = false)
        if non_block
          if empty?
            debug 'non-blocking and empty, raising ThreadError ...'
            raise ThreadError
          else
            debug 'non-blocking but NOT empty, shifting ...'
          end
        else
          while empty?
            debug 'blocking and empty, sleeping for 0.1 ...'
            sleep 0.1
          end
        end
        res = shift
        debug_var :res, res
        res
      end

      alias deq pop

    end
  end
end