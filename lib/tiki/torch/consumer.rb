# -*- encoding: utf-8 -*-

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
        info "Event ##{event.id} was processed"
      end

      def on_start(event)
        info "Event ##{event.id} started"
      end

      def on_success(event, result)
        event.acknowledge
        info "Event ##{event.id} succeeded with #{result.inspect}"
      end

      def on_failure(event, exception)
        event.reject
        error "Event ##{event.id} failed with #{exception.class.name} : #{exception.message}\n  #{exception.backtrace[0, 5].join("\n  ")}"
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
            @queue_name = new_name.to_s.underscore
          else
            @queue_name ||= name.underscore
          end
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
            result = instance.process event
            debug_var :result, result
            success_result = instance.on_success event, result
            debug_var :success_result, success_result
          rescue => e
            failure_result = instance.on_failure event, e
            debug_var :failure_result, failure_result
          end
        end

      end

    end
  end
end