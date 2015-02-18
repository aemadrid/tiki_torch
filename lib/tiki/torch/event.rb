# -*- encoding: utf-8 -*-

require 'multi_json'
require 'forwardable'

module Tiki
  module Torch
    class Event

      extend Forwardable
      include Logging

      attr_reader :payload, :delivery, :metadata, :headers

      def initialize(payload, delivery, metadata, headers)
        debug_var :payload, payload
        debug_var :delivery, delivery
        debug_var :metadata, metadata
        debug_var :headers, headers

        @payload  = payload
        @delivery = delivery
        @metadata = metadata
        @headers  = headers

        @body = payload
        debug_var :body, @body
      end

      delegate [:[]] => :body
      delegate [:consumer_tag, :delivery_tag, :redelivered, :routing_key, :exchange] => :delivery
      delegate [:message_id, :timestamp] => :metadata
      def_delegator :metadata, :message_id, :id

      attr_reader :body

      def acknowledge
        res = queue_broker.acknowledge_event self
        debug_var :res, res
        res
      end

      def reject
        res = queue_broker.reject_event self
        debug_var :res, res
        res
      end

      def publish(routing_key, payload = {}, properties = {})
        debug "Publishing message to #{routing_key} ..."
        res = queue_broker.publish_event routing_key, payload, properties
        debug_var :res, res
        res
      end

      def to_s
        attrs = {
          :@body        => body.to_s,
          message_id:   message_id,
          routing_key:  routing_key,
          delivery_tag: delivery_tag.to_i,
          timestamp:    timestamp,
        }
        "#<Tiki::Torch::Event #{attrs.map { |k, v| "#{k}=#{v.inspect}" }.join(', ')}>"
      end

      alias :inspect :to_s

      private

      def queue_broker
        Torch.queue_broker
      end

    end
  end
end