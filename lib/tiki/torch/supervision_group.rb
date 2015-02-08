# -*- encoding: utf-8 -*-

module Tiki
  module Torch
    class SupervisionGroup < Celluloid::SupervisionGroup

      supervise Tiki::Torch.config.connection_class, as: :tiki_torch_connection
      supervise QueueBroker, as: :tiki_torch_queue_broker
      pool EventProcessor, as: :tiki_torch_event_processor_pool
      supervise EventBroker, as: :tiki_torch_event_broker

      def connection
        @registry[:tiki_torch_connection]
      end

      def queue_broker
        @registry[:tiki_torch_queue_broker]
      end

      def processor_pool
        @registry[:tiki_torch_event_processor_pool]
      end

      def event_broker
        @registry[:tiki_torch_event_broker]
      end

    end
  end
end