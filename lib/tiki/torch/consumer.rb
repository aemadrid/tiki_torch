# -*- encoding: utf-8 -*-
require 'concurrent/atomic/atomic_fixnum'

require 'set'

module Tiki
  module Torch
    module Consumer

      def self.included(base)
        base.send :include, Logging
        base.extend ClassMethods
        EventBroker.register_consumer base
      end

      def process(event)
        debug "Event ##{event.id} was processed"
      end

      def on_start(event)
        debug "Event ##{event.id} started"
      end

      def on_success(event, result)
        event.acknowledge
        info "Event ##{event.id} succeeded with #{result.inspect}"
      end

      def on_failure(event, exception)
        event.reject
        error "Event ##{event.id} failed with #{exception.class.name} : #{exception.message}\n  #{exception.backtrace[0, 5].join("\n  ")}"
      end

      def publish(routing_key, payload = {}, properties = {})
        Torch.publish_message routing_key, payload, properties
      end

      module ClassMethods

        def consume(*new_routing_keys)
          # debug_var :routing_keys_1, routing_keys
          # debug_var :new_routing_keys, new_routing_keys
          # routing_keys.union new_routing_keys
          new_routing_keys.each { |x| routing_keys.add x }
          debug_var :routing_keys, routing_keys
          debug_var :new_routing_keys, new_routing_keys
        end

        def queue_name(new_name = nil)
          if new_name
            @queue_name = default_queue_name new_name
          else
            @queue_name || default_queue_name
          end
        end

        def default_queue_name(suffix = name)
          "#{Torch.config.consumer_queue_prefix}#{suffix.to_s.underscore}"
        end

        def routing_keys
          @routing_keys ||= Set.new
        end

        def process(event)
          instance = new
          debug_var :instance, instance
          begin
            start_result = instance.on_start event
            debug_var :start_result, start_result
            stats[:started].increment
            result = instance.process event
            debug_var :result, result
            stats[:processed].increment
            success_result = instance.on_success event, result
            debug_var :success_result, success_result
            stats[:succeeded].increment
          rescue => e
            failure_result = instance.on_failure event, e
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