# -*- encoding: utf-8 -*-

require 'celluloid'

module Tiki
  module Torch
    class EventBroker

      include Logging
      include Celluloid

      finalizer :finalize

      attr_reader :timers, :broker, :pool

      def initialize(min_secs = config.event_broker_wait, stopped = !config.poll_for_events)
        @min_secs = min_secs
        @polling  = false
        @stopped  = stopped

        setup_links
        setup_queues
        setup_timers
      end

      def self.consumer_registry
        @consumer_registry ||= []
      end

      def self.register_consumer(consumer_class)
        debug_var :consumer_registry, consumer_registry
        debug_var :consumer_class, consumer_class
        return false if consumer_registry.any? { |x| x.name == consumer_class.name }
        res = consumer_registry << consumer_class
        debug_var :consumer_registry, consumer_registry
        res
      end

      def start
        return false if @stopped

        @stopped = true
      end

      def stop_and_wait(wait_time = 2)
        return true if @stopped

        sleep_time = wait_time / 8.0
        debug 'stopping ...'
        @stopped = true
        end_time = Time.now + wait_time
        while !fully_stopped? && Time.now < end_time
          debug "waiting for #{sleep_time} ..."
          sleep sleep_time
        end
        fully_stopped?
      end

      private

      def fully_stopped?
        @stopped && !@polling
      end

      def config
        Tiki::Torch.config
      end

      def setup_links
        debug 'Setting up links ...'
        @broker = Actor[:tiki_torch_queue_broker]
        link @broker
        debug "@broker : #{@broker.inspect}"

        @pool = Actor[:tiki_torch_event_processor_pool]
        link @pool
        debug "@pool : #{@pool.inspect}"
        debug 'Done setting up links ...'
      end

      def setup_queues
        debug 'Setting up queues ...'
        self.class.consumer_registry.each do |consumer_class|
          debug "going to setup queue for #{consumer_class.name} : #{consumer_class.queue_name} : #{consumer_class.routing_keys.inspect} ..."
          raise "No routing keys for #{consumer_class.name} : #{consumer_class.queue_name}" if consumer_class.routing_keys.empty?
          @broker.setup_queue consumer_class.queue_name, consumer_class.routing_keys
        end
        debug 'Done setting up queues ...'
      end

      def setup_timers
        debug "Setting up timers for #{@min_secs} ..."
        every(@min_secs) do
          if @stopped
            debug 'Stopped, not going to check for events ...'
          else
            debug 'Going to check for events ...'
            if ready_for_events?
              debug 'Going to poll for events ...'
              poll_for_events
            else
              debug 'Not ready for events ...'
            end
          end
        end
        debug 'Done setting up timers ...'
      end

      def ready_for_events?
        if @stopped
          warn 'Stopped, not trying ...'
          false
        else
          if @polling
            warn 'Already polling, wait until next turn ...'
            false
          else
            if self.class.consumer_registry.empty?
              error 'No event classes ...'
              false
            else
              debug 'Ready for events!'
              true
            end
          end
        end
      end

      def poll_for_events
        @polling = true
        self.class.consumer_registry.each do |consumer_class|
          debug "going to poll for #{consumer_class.name} ..."
          if (idle_size = @pool.idle_size) > 0
            debug "pool is ready : #{idle_size}"
            poll_for_event consumer_class
          else
            error "pool is not ready : #{idle_size}"
          end
        end
        @polling = false
      end

      def poll_for_event(consumer_class)
        debug "Checking for #{consumer_class} ..."
        message = @broker.pull_event consumer_class.queue_name
        process_message consumer_class, message
      end

      def process_message(consumer_class, event)
        if event
          debug "Processing event #{event}"
          pool.async.process consumer_class, event
        else
          debug "No event found for #{consumer_class}"
        end
      end

      def finalize
        debug 'finalizing ...'
        stop_and_wait
        debug 'finalized ...'
      end

    end
  end
end