module Tiki
  module Torch
    class ThreadPool

      class NotReadyError < RuntimeError
      end

      extend Forwardable

      delegate [:busy_size, :shutdown] => :@pool

      def initialize(name, size)
        @name = name
        @pool = ::Lifeguard::InfiniteThreadpool.new pool_size: size
      end

      def busy?
        @pool.pool_size == @pool.busy_size
      end

      def ready?
        !busy?
      end

      def free?
        @pool.busy_size == 0
      end

      def async(*args, &block)
        raise(NotReadyError, 'Not ready to run async jobs') unless ready?

        @pool.async *args, &block
      end

      def to_s
        %{#<TP:#{@name}|#{busy_size}/#{@pool.pool_size}|#{free? ? 'F' : 'f'}:#{ready? ? 'R' : 'r'}:#{busy? ? 'B' : 'b'}>}
      end

      alias :inspect :to_s

    end

  end
end
