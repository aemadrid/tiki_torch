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
    class MarchHareConnection < RemoteConnection

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

        attr_reader :content_type, :content_encoding, :headers, :delivery_mode, :priority, :correlation_id, :reply_to,
                    :expiration, :message_id, :timestamp, :type, :user_id, :app_id, :cluster_id

        def initialize(headers)
          @content_type     = headers.content_type
          @content_encoding = headers.content_encoding
          @headers          = headers.headers
          @delivery_mode    = headers.delivery_mode
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

      def new_connection(url, settings)
        options = parsed_url_and_settings url, settings
        driver_class.connect options
      end

      def pull_message(queue_name)
        headers, payload = get_queue(queue_name).pop block: false, ack: true
        # debug_var :headers, headers, :to_yaml
        # debug_var :payload, payload

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

      def driver_class
        MarchHare
      end

      def build_event(payload, headers)
        Tiki::Torch::Event.new payload,
                               Delivery.new(headers),
                               Metadata.new(headers),
                               headers.properties
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
        rescue driver_class::NotFound => _
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

    end
  end
end if TIKI_TORCH_MARCH_HARE_LOADED