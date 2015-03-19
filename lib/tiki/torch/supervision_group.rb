# -*- encoding: utf-8 -*-

require 'celluloid'

module Tiki
  module Torch
    class SupervisionGroup < Celluloid::SupervisionGroup

      pool EventProcessor, as: :tiki_torch_event_processor_pool, size: Torch.config.event_pool_size
      supervise EventBroker, as: :tiki_torch_event_broker

      def processor_pool
        @registry[:tiki_torch_event_processor_pool]
      end

      def event_broker
        @registry[:tiki_torch_event_broker]
      end

    end

    extend self

    def group
      unless @group
        @group   ||= SupervisionGroup.run!
        @running = true
      end
      @group
    end

    alias :run :group

    def running?
      !(@group.nil? && @running.nil?)
    end

    def shutdown
      return false unless running?

      stop_polling
      logger.info 'terminating group ...'
      group.terminate
      logger.info 'terminated group ...'

      @group   = nil
      @running = false
      true
    end

    alias :stop :shutdown

    def event_processor_pool
      group.event_processor_pool
    end

    def event_broker
      group.event_broker
    end

  end
end