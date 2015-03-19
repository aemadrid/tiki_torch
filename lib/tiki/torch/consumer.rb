# -*- encoding: utf-8 -*-
require 'concurrent/atomic/atomic_fixnum'
require 'set'
require 'nsq'

module Tiki
  module Torch
    module Consumer

      def self.included(base)
        base.send :include, Logging
        base.extend ClassMethods
        EventBroker.register_consumer base
      end

      attr_reader :event

      def initialize(event)
        @event = event
      end

      def process
        debug "Event ##{event.id} was processed"
      end

      def on_start
        debug "Event ##{event.id} started"
      end

      def on_success(result)
        event.finish
        info "Event ##{event.id} succeeded with #{result.inspect}"
      end

      def on_failure(exception)
        event.requeue
        error "Event ##{event.id} failed with #{exception.class.name} : #{exception.message}\n  #{exception.backtrace[0, 5].join("\n  ")}"
      end

      def publish(topic_name, payload = {}, properties = {})
        Torch.publish_message topic_name, payload, properties
      end

      module ClassMethods

        def topic(name = nil)
          if name.nil?
            @topic || name.to_s.underscore
          else
            @topic = name
          end
        end

        def channel(name = nil)
          if name.nil?
            @channel || 'events'
          else
            @channel = name
          end
        end

        def connection
          @connection ||= ::Nsq::Consumer.new Torch.config.consumer_connection_options(topic, channel)
        end

        def pop
          if connection.size > 0
            Event.new connection.pop
          else
            nil
          end
        end

        def process(event)
          instance = new event
          debug_var :instance, instance
          begin
            start_result = instance.on_start
            debug_var :start_result, start_result
            stats[:started].increment
            result = instance.process
            debug_var :result, result
            stats[:processed].increment
            success_result = instance.on_success result
            debug_var :success_result, success_result
            stats[:succeeded].increment
          rescue => e
            failure_result = instance.on_failure e
            debug_var :failure_result, failure_result
            stats[:failed].increment
          end
        end

        def stats
          @stats ||= {
              started:   Concurrent::AtomicFixnum.new(0),
              processed: Concurrent::AtomicFixnum.new(0),
              succeeded: Concurrent::AtomicFixnum.new(0),
              failed:    Concurrent::AtomicFixnum.new(0),
          }
        end

        def stats_hash
          stats.each_with_object({}) { |(k, v), h| h[k] = v.value }
        end

      end

    end
  end
end