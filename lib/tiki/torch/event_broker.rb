# -*- encoding: utf-8 -*-

require 'celluloid'

module Tiki
  module Torch
    class EventBroker

      include Logging
      include Celluloid

      finalizer :finalize

      attr_reader :pool, :stats

      def initialize
        setup_stats
        setup_links
        setup_topics
        async.poll_for_events_loop
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

      def stop_and_wait(wait_time = 2)
        return true if fully_stopped?

        sleep_time = wait_time / 8.0
        info 'stopping ...'
        @stopped = true
        end_time = Time.now + wait_time
        cnt      = 0
        while !fully_stopped? && Time.now < end_time
          cnt += 1
          info "#{cnt} | waiting until #{end_time} for #{sleep_time} ..."
          sleep sleep_time
        end
        fully_stopped?
      end

      alias :stop :stop_and_wait
      alias :stop_polling :stop_and_wait

      def stats_hash
        stats.each_with_object({}) { |(k, v), h| h[k] = v.value }
      end

      private

      def fully_stopped?
        res = @stopped && !@polling && @pool.busy_size == 0
        debug "res : #{res} | @stopped : #{@stopped} | @polling : #{@polling} | @pool.busy_size : #{@pool.busy_size}"
        res
      end

      def config
        Tiki::Torch.config
      end

      def setup_links
        @pool = Actor[:tiki_torch_event_processor_pool]
        link @pool
        debug "@pool : #{@pool.inspect}"
        debug 'Done setting up links ...'
      end

      def setup_topics
        debug 'Setting up queues ...'
        self.class.consumer_registry.each do |consumer_class|
          debug "going to check connection for #{consumer_class.name} : #{consumer_class.topic} : #{consumer_class.channel} ..."
          res = consumer_class.connection.connected?
          debug "#{consumer_class.name} : #{consumer_class.topic} : #{consumer_class.channel} : connected : [#{res}] ..."
        end
        debug 'Done setting up queues ...'
      end

      def poll_for_events_loop
        while true
          cnt = stats[:looped].increment
          debug " [#{cnt}] ".center(60, '=')
          if ready_for_events?
            debug "[#{cnt}] We are ready for events, going to poll ..."
            poll_for_events
            sleep_time = Torch.config.events_busy_sleep_time
            if sleep_time > 0
              debug "[#{cnt}] Already polled for events, sleeping for #{sleep_time} seconds ..."
              sleep sleep_time
            end
          else
            sleep_time = Torch.config.events_idle_sleep_time
            debug "[#{cnt}] We are NOT ready for events, sleeping for #{sleep_time} seconds ..."
            sleep sleep_time
          end
        end
      end

      def ready_for_events?
        if Torch.config.poll_for_events
          if @polling
            warn 'Already polling, wait until next turn ...'
            stats[:polling].increment
            false
          else
            if self.class.consumer_registry.empty?
              stats[:empty].increment
              error 'No event classes ...'
              false
            else
              debug 'Ready for events!'
              stats[:ready].increment
              true
            end
          end
        else
          warn 'Stopped, not trying ...'
          stats[:stopped].increment
          false
        end
      end

      def poll_for_events
        debug 'Starting polling ...'
        @polling = true
        stats[:polled].increment
        self.class.consumer_registry.each do |consumer_class|
          debug "going to poll for #{consumer_class.name} ..."

          if (idle_size = @pool.idle_size) > 0
            debug "pool is ready : #{idle_size}"
            poll_for_event consumer_class
          else
            error "pool is not ready : #{idle_size}"
            stats[:busy].increment
          end
        end
        debug 'Stopping polling ...'
        @polling = false
      end

      def poll_for_event(consumer_class)
        debug "Checking for #{consumer_class} ..."
        if (event = consumer_class.pop)
          debug "Got #{event.class.name} for #{consumer_class}, going to process ..."
          stats[:processed].increment
          process_event consumer_class, event
        end
      end

      def process_event(consumer_class, event)
        debug "Processing event #{event}"
        pool.async.process consumer_class, event
      end

      def setup_stats
        @stats = {
            looped:    Concurrent::AtomicFixnum.new(0),
            stopped:   Concurrent::AtomicFixnum.new(0),
            polling:   Concurrent::AtomicFixnum.new(0),
            empty:     Concurrent::AtomicFixnum.new(0),
            ready:     Concurrent::AtomicFixnum.new(0),
            polled:    Concurrent::AtomicFixnum.new(0),
            processed: Concurrent::AtomicFixnum.new(0),
            busy:      Concurrent::AtomicFixnum.new(0),
        }
      end

      def finalize
        # debug "Finalizing ##{object_id} ..."
        # stop_and_wait
        debug "Finalized ##{object_id} ..."
        true
      end

    end

    extend self

    def start_polling
      config.poll_for_events = true
    end

    def stop_polling
      config.poll_for_events = false
    end

  end
end