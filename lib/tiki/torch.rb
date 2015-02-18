require 'pathname'
require 'celluloid'
require 'forwardable'
require 'tiki/torch/version'
require 'tiki/torch/core_ext'

module Tiki
  module Torch

    extend self

    def root
      ::Pathname.new File.expand_path('../../', __FILE__)
    end

    attr_writer :logger

    def logger
      @logger || Celluloid.logger
    end

    def group
      unless @group
        @group   = SupervisionGroup.run!
        @running = true
      end
      @group
    end

    alias_method :run, :group

    def running?
      !(@group.nil? && @running.nil?)
    end

    def shutdown
      return false unless running?

      logger.info 'terminating group ...'
      group.terminate
      logger.info 'terminated group ...'

      @group   = nil
      @running = false
      true
    end

    def connection
      group.connection
    end

    def queue_broker
      group.queue_broker
    end

    def event_processor_pool
      group.event_processor_pool
    end

    def event_broker
      group.event_broker
    end

    def publish(routing_key, payload = {}, properties = {})
      queue_broker.publish_event routing_key, payload, properties
    end

  end
end

require 'tiki/torch/logging'
require 'tiki/torch/config'
require 'tiki/torch/connection'
require 'tiki/torch/consumer'
require 'tiki/torch/event'
require 'tiki/torch/event_broker'
require 'tiki/torch/event_processor'
require 'tiki/torch/queue_broker'
require 'tiki/torch/supervision_group'
