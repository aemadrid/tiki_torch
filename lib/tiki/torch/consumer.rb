# -*- encoding: utf-8 -*-
require 'set'

module Tiki
  module Torch
    class Consumer

      include Logging
      extend Forwardable

      def self.inherited(subclass)
        ConsumerBroker.register_consumer subclass
      end

      def initialize(event)
        @event = event
      end

      attr_reader :event
      delegate [:message, :payload, :properties, :message_id] => :event
      delegate [:body, :attempts, :timestamp] => :message

      def process
        debug "Event ##{message_id} was processed"
      end

      def on_start
        debug "Event ##{message_id} started"
      end

      def on_success(result)
        event.finish
        info "Event ##{message_id} succeeded with #{result.inspect}"
      end

      def on_failure(exception)
        event.requeue
        error "Event ##{message_id} failed with #{exception.class.name} : #{exception.message}\n  #{exception.backtrace[0, 5].join("\n  ")}"
      end

      def publish(topic_name, payload = {}, properties = {})
        Torch.publish topic_name, payload, properties
      end

      class << self

        def topic(name = nil)
          if name.nil?
            @topic || name.to_s.underscore
          else
            new_name = "#{Torch.config.topic_prefix}#{name}"
            raise "Invalid topic name [#{name}]" unless valid_topic_name? new_name
            @topic = new_name
          end
        end

        def channel(name = nil)
          if name.nil?
            @channel || 'events'
          else
            raise "Invalid channel name [#{name}]" unless valid_topic_name? name
            @channel = name
          end
        end

        def nsqd(address = nil)
          if address.nil?
            @nsqd || Torch.config.nsqd
          else
            @nsqd = address
          end
        end

        def nsqlookupd(address = nil)
          if address.nil?
            @nsqlookupd || Torch.config.nsqlookupd
          else
            @nsqlookupd = address
          end
        end

        def max_in_flight(value = nil)
          if value.nil?
            @max_in_flight || Torch.config.max_in_flight
          else
            @max_in_flight = value
          end
        end

        def discovery_interval(value = nil)
          if value.nil?
            @discovery_interval || Torch.config.discovery_interval
          else
            @discovery_interval = value
          end
        end

        def msg_timeout(value = nil)
          if value.nil?
            @msg_timeout || Torch.config.msg_timeout
          else
            @msg_timeout = value
          end
        end

        def connection_options
          options = {
            nsqd:               nsqd,
            nsqlookupd:         nsqlookupd,
            topic:              topic,
            channel:            channel,
            max_in_flight:      max_in_flight,
            discovery_interval: discovery_interval,
            msg_timeout:        msg_timeout,
          }
          debug_var :options, options
          options
        end

        def connection
          @connection ||= ::Nsq::Consumer.new connection_options
        end

        attr_reader :event_pool, :stats

        def busy_size
          event_pool ? event_pool.busy_size : 0
        end

        def start
          debug 'starting ...'

          res = connection.connected?
          debug "connected : #{res}"

          debug 'setting up stats'
          @stats ||= Stats.new :started, :processed, :succeeded, :failed

          debug 'setting up process pool ...'
          @process_pool ||= Torch::ThreadPool.new :process, 2
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

        def process_loop
          debug 'Started running process loop ...'
          until @stopped
            @event_pool ||= Torch::ThreadPool.new :events, Torch.config.event_pool_size
            # debug "got pool #{@event_pool} ..."
            if @event_pool.ready?
              debug "event pool is ready : #{@event_pool}"
              msg = connection.pop
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
          sleep_time = Torch.config.events_sleep_times[name]
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
          end
        end

        private

        TOPIC_NAME_RX   = /^[\.a-zA-Z0-9_-]+$/
        CHANNEL_NAME_RX = /^[\.a-zA-Z0-9_-]+(#ephemeral)?$/

        def valid_topic_name?(name)
          return false if name.size < 1 || name.size > 32
          !!name.match(TOPIC_NAME_RX)
        end

        def valid_channel_name?(name)
          return false if name.size < 1 || name.size > 32
          !!name.match(CHANNEL_NAME_RX)
        end

      end

    end
  end
end