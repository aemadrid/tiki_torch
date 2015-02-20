# -*- encoding: utf-8 -*-

module Tiki
  module Torch
    class RemoteConnection < Connection

      class TCPConnectionFailed < StandardError

        attr_reader :url

        def initialize(message, url)
          super("Could not establish TCP connection to #{url}: #{message}")
        end

      end

      def connect!
        return if connected?

        start_connection!

        if connected?
          info "Connected to RabbitMQ: #{config.connection_url}"
          set_exchange_return_handler!
          true
        else
          error "Failed to connect to RabbitMQ: #{config.connection_url}"
          false
        end
      end

      def setup_queue(queue_name, routing_keys)
        connect!

        if queue_exists? queue_name
          debug "Queue #{queue_name} already exists..."
          return false
        end

        channel.queue(queue_name, config.consumer_queue_options).tap do |queue|
          debug "Binding queue #{queue_name} to #{routing_keys.inspect} ..."
          routing_keys.each do |key|
            debug "Binding queue #{queue_name} to #{key.inspect} ..."
            queue.bind exchange, routing_key: key
          end
        end
      end

      def get_queue(queue_name, options = {})
        connect!
        channel.queue queue_name, config.consumer_queue_options.merge(options)
      end

      def publish_message(routing_key, payload = {}, properties = {})
        raise "invalid payload [#{payload.class.name}]" unless payload.respond_to?(:to_hash)
        encoded_payload      = config.payload_encoding_handler.call payload.to_hash
        options              = config.publish_options.merge(routing_key: routing_key)
        options[:properties] = config.publish_properties.merge properties
        debug_var :encoded_payload, encoded_payload
        debug_var :options, options
        res = exchange.publish encoded_payload, options
        debug_var :res, res
        res
      end

      def acknowledge_message(delivery_tag)
        connect!
        channel.acknowledge delivery_tag
      end

      def reject_message(delivery_tag)
        connect!
        channel.reject delivery_tag, true
      end

      private

      def driver_class
        raise 'not implemented'
      end

      def start_connection!
        begin
          attempt_connection
        rescue TCPConnectionFailed => e
          if connection_attempts < config.connection_attempts
            retry
          else
            attempts             = connection_attempts
            @connection_attempts = 0
            raise TCPConnectionFailed.new "Failed to connect to RabbitMQ server after #{attempts} attempts", config.connection_url
          end
        end
      end

      def config
        Tiki::Torch.config
      end

      def attempt_connection
        @connection_attempts += 1
        logger.warn "Connecting to RabbitMQ: #{config.connection_url}. Attempt #{connection_attempts} of #{config.connection_attempts}" if connection_attempts > 1

        @connection = new_connection config.connection_url, config.connection_settings
        @connection.start
        @connection_attempts = 0
      end

      def close
        warn "closing connection to RabbitMQ: #{config.connection_url}"
        connection.close if connected?
        @channel  = nil
        @exchange = nil
      end

      def connected?
        connection && connection.connected?
      end

      def exchange
        unless @exchange
          debug_var :config_exchange_name, config.exchange_name
          @exchange = channel.topic config.exchange_name, config.exchange_options
          # debug_var :@exchange, @exchange
        end
        @exchange
      end

    end
  end
end