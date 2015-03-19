# -*- encoding: utf-8 -*-

require 'thread'
require 'nsq'

module Tiki
  module Torch
    class Publisher

      def initialize
        @producers = Hash.new
        @mutex     = ::Mutex.new
        at_exit { terminate_producers }
      end

      def publish(topic_name, payload = {}, properties = {})
        encoded = Torch.config.payload_encoding_handler.call payload, properties
        get_or_set(topic_name).write encoded
      end

      private

      def get_or_set(name)
        key = name.to_s.underscore
        @mutex.synchronize do
          get(key) || set(key)
        end
      end

      def get(key)
        @producers[key]
      end

      def set(key)
        @producers[key] = ::Nsq::Producer.new Torch.config.producer_connection_options(key)
      end

      def terminate_producers
        @producers.values.each { |p| p.terminate }
      end

    end

    extend self

    def publisher
      @publisher ||= Publisher.new
    end

    publisher

    def publish(topic_name, payload = {}, properties = {})
      publisher.publish topic_name, payload, properties
    end

  end
end