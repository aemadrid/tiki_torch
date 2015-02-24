# -*- encoding: utf-8 -*-

module Tiki
  module Torch
    class Connection

      include Logging
      include Celluloid

      attr_reader :connection, :connection_attempts

      def initialize
        @connection_attempts = 0
      end

      def pull_message(queue_name)
        raise 'not implemented'
      end

      def publish_message(routing_key, payload = {}, properties = {})
        raise 'not implemented'
      end

      def acknowledge_message(delivery_tag)
        raise 'not implemented'
      end

      def reject_message(delivery_tag)
        raise 'not implemented'
      end

      def parsed_url_and_settings(url, settings = {})
        uri     = URI.parse url
        options = settings

        if (hosts = uri.host.split('--')).size > 1
          options[:hosts] = hosts
        else
          options[:host] = uri.host || '127.0.0.1'
        end
        options[:port]     = uri.port || 5672
        options[:username] = uri.userinfo ? uri.userinfo.split(':').first : 'guest'
        options[:password] = uri.userinfo ? uri.userinfo.split(':').last : 'guest'
        options[:vhost]    = uri.path.empty? ? '/' : uri.path[1..-1]

        debug_var :options, options
        options
      end

    end
  end
end
require 'tiki/torch/connection/local'
require 'tiki/torch/connection/march_hare'
require 'tiki/torch/connection/bunny'
