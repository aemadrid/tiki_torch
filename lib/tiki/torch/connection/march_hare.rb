# -*- encoding: utf-8 -*-

require 'uri'
require 'ostruct'

begin
  require 'march_hare'
  TIKI_TORCH_MARCH_HARE_LOADED = true
rescue LoadError
  TIKI_TORCH_MARCH_HARE_LOADED = false
end

module Tiki
  module Torch
    class MarchHareConnection < Connection

      include Celluloid
      include Celluloid

      finalizer :finalize

      class TCPConnectionFailed < StandardError

        attr_reader :url

        def initialize(message, url)
          super("Could not establish TCP connection to #{url}: #{message}")
        end

      end

      class Delivery

        attr_reader :consumer_tag, :delivery_tag, :redelivered, :routing_key

        def initialize(headers)
          @consumer_tag = headers.consumer_tag
          @delivery_tag = headers.delivery_tag
          @redelivered  = headers.redelivered?
          @routing_key  = headers.routing_key
        end

      end

      class Metadata

        attr_reader :content_type, :content_encoding, :delivery_mode, :headers, :priority, :correlation_id, :reply_to,
                    :expiration, :message_id, :timestamp, :type, :user_id, :app_id, :cluster_id

        def initialize(headers)
          @content_type     = headers.content_type
          @content_encoding = headers.content_encoding
          @delivery_mode    = headers.delivery_mode
          @headers          = headers.headers
          @priority         = headers.priority
          @correlation_id   = headers.correlation_id
          @reply_to         = headers.reply_to
          @expiration       = headers.expiration
          @message_id       = headers.message_id
          @timestamp        = headers.timestamp ? Time.at(headers.timestamp.getTime / 1000) : nil
          @type             = headers.type
          @user_id          = headers.user_id
          @app_id           = headers.app_id
          @cluster_id       = headers.cluster_id
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
        res = exchange.publish *build_message(routing_key, payload, properties)
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

      def new_connection
        new_connection_from_options || new_connection_from_url || MarchHare.connect()
      end

      def new_connection_from_options
        return false unless config.connection_options

        debug_var :options_from_config, config.connection_options.merge(config.connection_settings)
        MarchHare.connect options
      end

      def new_connection_from_url
        return false unless config.connection_url

        options = parsed_url_and_settings config.connection_url, config.connection_settings
        debug_var :options_from_url, options
        MarchHare.connect options
      end

      def pull_message(queue_name)
        headers, payload = get_queue(queue_name).pop block: false, ack: true
        if payload.nil? && headers.nil?
          debug 'No message found ...'
          nil
        else
          debug 'found 1 message ...'
          event = build_event payload, headers
          debug_var :event, event
          event
        end
      end

      private

      def build_message(routing_key, payload, properties)
        encoded_payload      = config.payload_encoding_handler.call payload.to_hash
        options              = config.publish_options.merge(routing_key: routing_key)
        options[:properties] = config.publish_properties.merge properties
        debug_var :encoded_payload, encoded_payload
        debug_var :options, options
        [encoded_payload, options]
      end

      def build_event(payload, headers)
        Tiki::Torch::Event.new payload,
                               Delivery.new(headers),
                               Metadata.new(headers)
      end

      def channel
        connect!
        @channel ||= connection.create_channel.tap { |c| c.prefetch = config.channel_prefetch }
      end

      def set_exchange_return_handler!
        # Nothing to do here yet
      end

      def queue_exists?(name)
        connect!
        ch = connection.create_channel
        begin
          ch.queue name, config.consumer_queue_options.merge(passive: true)
          true
        rescue MarchHare::NotFound => _
          false
        ensure
          ch.close if ch.open?
        end
      end

      def finalize
        debug 'finalizing ...'
        close
        debug 'finalized ...'
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

        @connection = new_connection
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
end if TIKI_TORCH_MARCH_HARE_LOADED