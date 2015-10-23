module Tiki
  module Torch
    class ConsumerPoller

      include Logging
      extend Forwardable

      def_delegators :@consumer, :queue_name, :use_dlq, :dlq_postfix, :visibility_timeout

      def initialize(consumer, client)
        @consumer = consumer
        @client   = client
      end

      def pop(qty = 1, timeout = 0)
        options = {
          max_number_of_messages: max_qty(qty),
          wait_time_seconds:      timeout,
          visibility_timeout:     visibility_timeout,
        }
        queue.receive_messages options
      end

      def to_s
        %{#<T:T:CP|#{queue_name}>}
      end

      alias :inspect :to_s

      private

      def queue
        @queue ||= @client.queue queue_name
      end

      def max_qty(qty)
        qty > 10 ? 10 : qty
      end

    end
  end
end
