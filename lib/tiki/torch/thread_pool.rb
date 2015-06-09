require 'lifeguard'
require 'forwardable'

module Tiki
  module Torch
    class ThreadPool

      extend Forwardable

      delegate [:busy_size, :async, :shutdown] => :@pool

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

      def ready_size
        ready_size = @pool.pool_size - @pool.busy_size
        return ready_size >= 0 ? ready_size : 0
      end

      def to_s
        %{#<#{self.class.name} name=#{@name} size=#{@pool.pool_size} idle=#{ready_size} busy=#{busy_size} ready=#{ready?} free=#{free?}>}
      end

    end

  end
end
