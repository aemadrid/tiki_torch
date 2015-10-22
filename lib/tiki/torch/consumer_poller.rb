module Tiki
  module Torch
    class ConsumerPoller

      include Logging
      extend Forwardable

      def_delegators :@consumer, :queue_name, :create_dlq, :max_dlq, :dlq_postfix

      def initialize(consumer, client)
        @consumer = consumer
        @client   = client
      end

      def pop(qty = 1, timeout = 0)
        options = {
          max_number_of_messages: max_qty(qty),
          wait_time_seconds:      timeout,
          visibility_timeout:     @consumer.visibility_timeout,
        }
        queue.receive_messages options
      end

      def to_s
        %{#<T:T:CP|#{queue_name}>}
      end

      alias :inspect :to_s

      private

      def queue
        @queue ||= @client.queue(queue_name).tap do |x|
          @client.create_and_attach_dlq x, "#{queue_name}-#{dlq_postfix}", max_dlq if create_dlq
        end
      end

      def max_qty(qty)
        qty > 10 ? 10 : qty
      end

    end
  end
end
