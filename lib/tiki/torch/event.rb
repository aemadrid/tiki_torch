# -*- encoding: utf-8 -*-

require 'multi_json'
require 'forwardable'

module Tiki
  module Torch
    class Event

      extend Forwardable
      include Logging

      attr_reader :payload, :delivery, :metadata, :properties

      def initialize(payload, delivery, metadata, properties)
        debug_var :payload, payload
        debug_var :delivery, delivery
        debug_var :metadata, metadata
        debug_var :properties, properties

        @payload    = payload
        @delivery   = delivery
        @properties = properties
        @metadata   = metadata

        @body = Tiki::Torch.config.payload_decoding_handler.call payload
        debug_var :body, @body
      end

      delegate [:[]] => :body
      delegate [:consumer_tag, :delivery_tag, :redelivered, :routing_key, :exchange] => :delivery
      delegate [:message_id, :timestamp] => :metadata
      def_delegator :metadata, :message_id, :id

      attr_reader :body

      def acknowledge
        debug "Acknowledging ##{id} with tag ##{delivery_tag.to_i} ..."
        res = Tiki::Torch.connection.acknowledge_message delivery_tag
        debug_var :res, res
        res
      end

      def reject
        debug "Rejecting ##{id} with tag ##{delivery_tag.to_i} ..."
        res = Tiki::Torch.connection.reject_message delivery_tag
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

    end
  end
end