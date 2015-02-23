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
        @stopped  = true

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
        return false unless @stopped

        @stopped = false
      end

      alias :start_polling :start

      def stop_and_wait(wait_time = 2)
        return true if fully_stopped?

        sleep_time = wait_time / 8.0
        info 'stopping ...'
        @stopped = true
        end_time = Time.now + wait_time
        cnt = 0
        while !fully_stopped? && Time.now < end_time
          cnt += 1
          info "#{cnt} | waiting until #{end_time} for #{sleep_time} ..."
          sleep sleep_time
        end
        fully_stopped?
      end

      alias :stop :stop_and_wait
      alias :stop_polling :stop_and_wait

      private

      def fully_stopped?
        res = @stopped && !@polling && pool_busy_size == 0
        debug "res : #{res} | @stopped : #{@stopped} | @polling : #{@polling} | pool_busy_size : #{pool_busy_size}"
        res
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
        debug 'Starting polling ...'
        @polling = true
        self.class.consumer_registry.each do |consumer_class|
          debug "going to poll for #{consumer_class.name} ..."
          break if sudden_stop?

          if (idle_size = pool_idle_size) > 0
            debug "pool is ready : #{idle_size}"
            poll_for_event consumer_class
          else
            error "pool is not ready : #{idle_size}"
          end
        end
        debug 'Stopping polling ...'
        @polling = false
      end

      def pool_idle_size
        @pool.idle_size
      end

      def pool_busy_size
        @pool.busy_size
      end

      def poll_for_event(consumer_class)
        return nil if sudden_stop?

        debug "Checking for #{consumer_class} ..."
        event = @broker.pull_event consumer_class.queue_name
        process_event consumer_class, event
      end

      def process_event(consumer_class, event)
        return nil if sudden_stop?

        if event
          debug "Processing event #{event}"
          pool.async.process consumer_class, event
        else
          debug "No event found for #{consumer_class}"
        end
      end

      def finalize
        info 'finalizing ...'
        stop_and_wait
        info 'finalized ...'
      end

      def sudden_stop?
        return false unless @stopped

        info 'Stopping on our tracks ...'
        @polling = false
        true
      end

    end
  end
end