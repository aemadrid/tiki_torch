# -*- encoding: utf-8 -*-

require 'celluloid'

module Tiki
  module Torch
    class QueueBroker

      include Logging
      include Celluloid

      finalizer :finalize

      def initialize
        setup_links
      end

      def setup_queue(queue_name, routing_keys)
        @connection.setup_queue queue_name, routing_keys
      end

      def publish_event(routing_key, payload = {}, properties = {})
        raise "invalid payload [#{payload.class.name}]" unless payload.respond_to?(:to_hash)
        encoded_payload      = config.payload_encoding_handler.call payload.to_hash
        options              = config.publish_options.merge(routing_key: routing_key).stringify_keys
        options[:properties] = config.publish_properties.merge(properties).stringify_keys
        debug_var :encoded_payload, encoded_payload
        debug_var :options, options
        res = @connection.publish_message encoded_payload, options
        debug_var :res, res
        res
      end

      def pull_event(queue_name)
        encoded_payload, delivery, metadata, headers = @connection.pull_message queue_name
        decoded_payload = config.payload_decoding_handler.call encoded_payload
        Torch::Event.new decoded_payload, delivery, metadata, headers
      end

      def acknowledge_event(event)
        debug "Acknowledging ##{event.id} with tag ##{event.delivery_tag.to_i} ..."
        res = @connection.acknowledge_message event.delivery_tag
        debug_var :res, res
        res
      end

      def reject_event(event)
        debug "Rejecting ##{event.id} with tag ##{event.delivery_tag.to_i} ..."
        res = @connection.reject_message event.delivery_tag
        debug_var :res, res
        res
      end

      private

      def setup_links
        @connection = Actor[:tiki_torch_connection]
        link @connection
      end

      def finalize
        debug 'Finalized ...'
      end

      def config
        Torch.config
      end

    end
  end
end