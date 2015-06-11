require 'set'

module Tiki
  module Torch
    class Consumer

      extend Forwardable

      include Logging

      include PublisherHelper
      include Hooks
      include BackOff

      def self.inherited(subclass)
        ConsumerBroker.register_consumer subclass
      end

      def initialize(event)
        @event = event
      end

      attr_reader :event

      delegate [:message, :payload, :properties, :message_id, :short_id] => :event
      delegate [:body, :attempts, :timestamp] => :message

      class << self

        def topic(name = nil)
          if name.nil?
            @topic || name.to_s.underscore
          else
            prefix = config.topic_prefix
            name   = "#{prefix}#{name}" unless name.start_with? prefix
            @topic = name
          end
        end

        def channel(name = nil)
          if name.nil?
            @channel || 'events'
          else
            @channel = name.to_s
          end
        end

        attr_reader :event_pool, :stats

        def busy_size
          event_pool ? event_pool.busy_size : 0
        end

        def start
          debug 'starting ...'

          res = poller.connected?
          debug "connected : #{res}"

          debug 'setting up stats'
          @stats ||= Stats.new :started, :processed, :succeeded, :failed

          debug 'setting up process pool ...'
          @process_pool ||= Tiki::Torch::ThreadPool.new :process, config.processor_count
          @stopped      = false

          debug 'starting process loop ...'
          @process_pool.async { process_loop }

          debug 'started ...'
        end

        def stop
          debug 'stopping ...'
          @stopped = true
          @process_pool.async { stop_events } if @process_pool
          debug 'sent stop message ...'
        end

        def stop_events
          debug 'stopping events ...'
          if event_pool
            cnt = 0
            until event_pool.free?
              cnt += 1
              debug "[#{cnt}] event #{event_pool} is not free"
              sleep 0.25
            end
            debug "shutting down #{event_pool} ..."
            event_pool.shutdown
            @event_pool = nil
          end
          debug 'done stopping events ...'
        end

        attr_accessor :nsqd, :nsqlookupd, :max_in_flight, :discovery_interval, :msg_timeout

        def poller
          @poller ||= Tiki::Torch::ConsumerPoller.new topic:              topic,
                                                      channel:            channel,
                                                      nsqd:               @nsqd,
                                                      nsqlookupd:         @nsqlookupd,
                                                      max_in_flight:      @max_in_flight,
                                                      discovery_interval: @discovery_interval,
                                                      msg_timeout:        @msg_timeout
        end

        attr_writer :back_off, :max_attempts, :back_off_time_unit

        def back_off_strategy
          @back_off || BackOffStrategies::Default
        end

        def max_attempts
          @max_attempts || config.max_attempts
        end

        def back_off_time_unit
          @back_off_time_unit || config.back_off_time_unit
        end

        attr_writer :event_pool_size

        def event_pool_size
          @event_pool_size || config.event_pool_size
        end

        def process_loop
          debug 'Started running process loop ...'
          until @stopped
            @event_pool ||= Tiki::Torch::ThreadPool.new(:events, event_pool_size)
            # debug "got pool #{@event_pool} ..."
            if @event_pool.ready?
              debug "event pool is ready : #{@event_pool}"
              msg = poller.pop
              if msg
                debug "got msg : #{msg}"
                event = Event.new msg
                debug "got event : #{event}, going to process async ..."
                @event_pool.async { process event }
                debug "sent to #{@event_pool}"
                sleep_for :busy unless @stopped
              else
                debug 'did not get a msg ...'
                sleep_for :empty unless @stopped
              end
            else
              debug "event pool is NOT ready : #{@event_pool}"
              sleep_for :busy unless @stopped
            end
          end
          debug 'Finished running process loop ...'
        end

        def sleep_for(name)
          sleep_time = config.events_sleep_times[name]
          debug "going to sleep on #{name} for #{sleep_time} secs ..."
          sleep sleep_time
        end

        def process(event)
          instance = new event
          debug_var :instance, instance
          begin
            start_result = instance.on_start
            debug_var :start_result, start_result
            stats.increment :started
            result = instance.process
            debug_var :result, result
            stats.increment :processed
            success_result = instance.on_success result
            debug_var :success_result, success_result
            stats.increment :succeeded
          rescue => e
            failure_result = instance.on_failure e
            debug_var :failure_result, failure_result
            stats.increment :failed
          ensure
            instance.on_end
          end
        end

        private

        def config
          Tiki::Torch.config
        end

      end

    end
  end
end