# -*- encoding: utf-8 -*-

begin
  require 'bunny'
  TIKI_TORCH_BUNNY_LOADED = true
rescue LoadError
  TIKI_TORCH_BUNNY_LOADED = false
end

module Tiki
  module Torch
    class BunnyConnection < RemoteConnection

      def new_connection(url, settings)
        driver_class.new url, settings
      end

      private

      def driver_class
        Bunny
      end

      def channel
        @channel ||= connection.create_channel.tap { |c| c.prefetch config.channel_prefetch }
      end

      def set_exchange_return_handler!
        exchange.on_return do |basic_return, metadata, payload|
          config.message_return_handler.call(basic_return, metadata, payload)
        end
      end

      def queue_exists?(name)
        connect!
        connection.queue_exists? name
      end

    end
  end
end if TIKI_TORCH_BUNNY_LOADED