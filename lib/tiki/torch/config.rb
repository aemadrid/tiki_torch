# -*- encoding: utf-8 -*-

require 'celluloid'
require 'securerandom'

module Tiki
  module Torch
    class Config

      include Logging

      attr_writer :connection_type, :connection_url, :connection_attempts

      def connection_type
        @connection_type ||= if ENV.fetch('TIKI_TORCH_CONNECTION_TYPE', '') == 'local'
                               'Local'
                             elsif ENV.fetch('TIKI_TORCH_CONNECTION_TYPE', '') == 'march_hare' || RUBY_PLATFORM == 'java'
                               'MarchHare'
                             else
                               'Bunny'
                             end
      end

      def connection_class_name
        "#{connection_type}Connection"
      end

      def connection_class
        Tiki::Torch.const_get connection_class_name
      end

      def connection_url
        @connection_url || ENV.fetch('RABBITMQ_URL', '')
      end

      def connection_attempts
        @connection_attempts || 5
      end

      def connection_settings
        {
          timeout:                   2,
          automatic_recovery:        true,
          on_tcp_connection_failure: connection_failed_handler,
        }
      end

      attr_writer :connection_failed_handler, :connection_loss_handler, :message_return_handler

      def connection_failed_handler
        @connection_failed_handler ||= lambda do
          error "RabbitMQ connection failure: #{connection_url}"
        end
      end

      def connection_loss_handler
        @connection_loss_handler ||= lambda do |conn|
          warn "RabbitMQ connection loss: #{connection_url}"
          conn.reconnect false, 2
        end
      end

      def message_return_handler
        @message_return_handler ||= lambda do |basic_return, metadata, payload|
          ary = [Event.parse_payload(payload), basic_return.reply_code, basic_return.reply_text, metadata[:headers]]
          warn 'Tiki::Torch message %s was returned! reply_code = %s, reply_text = %s headers = %s' % ary
        end
      end

      attr_writer :channel_prefetch, :exchange_name

      def channel_prefetch
        @channel_prefetch || 1
      end

      def exchange_name
        @exchange_name || 'tiki_torch'
      end

      def exchange_options
        @exchange_options ||= {
          durable:     true,
          auto_delete: false,
          exclusive:   false
        }
      end

      def consumer_queue_options
        @consumer_queue_options ||= {
          durable:     true,
          auto_delete: false,
          exclusive:   false
        }
      end

      def publish_options
        @publish_options ||= {
          persistent: true,
          mandatory:  false,
        }
      end

      attr_writer :app_id

      def app_id
        @app_id || 'missing'
      end

      def default_publish_properties
        @default_publish_properties ||= {
          priority:       5,
          type:           '',
          headers:        {},
          timestamp:      Time.now,
          reply_to:       nil,
          correlation_id: nil,
        }
      end

      def publish_properties
        default_publish_properties.merge app_id:       app_id,
                                         content_type: payload_content_type,
                                         message_id:   SecureRandom.hex

      end

      attr_writer :payload_encoding_handler, :payload_decoding_handler, :payload_content_type

      def payload_encoding_handler
        @payload_encoding_handler ||= lambda do |payload|
          MultiJson.dump payload
        end
      end

      def payload_decoding_handler
        @payload_decoding_handler ||= lambda do |payload|
          MultiJson.load payload, symbolize_keys: true
        end
      end

      def payload_content_type
        @payload_content_type || 'application/json'
      end

      attr_writer :event_broker_wait

      def event_broker_wait
        @event_broker_wait || 0.5
      end

    end

    def self.config
      @config ||= Config.new
    end

  end
end