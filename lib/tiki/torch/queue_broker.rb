# -*- encoding: utf-8 -*-

require 'celluloid'

module Tiki
  module Torch
    class QueueBroker

      include Logging
      include Celluloid

      finalizer :finalize

      def initialize
        setup_links
      end

      def setup_queue(queue_name, routing_keys)
        @connection.setup_queue queue_name, routing_keys
      end

      def pull_event(queue_name)
        @connection.pull_message queue_name
      end

      private

      def setup_links
        @connection = Actor[:tiki_torch_connection]
        link @connection
      end

      def finalize
        info 'Finalized ...'
      end

    end
  end
end