# -*- encoding: utf-8 -*-

require 'thread'
require 'nsq'

module Tiki
  module Torch
    class Publisher

      include Logging

      def initialize
        @producers = Hash.new
        @mutex     = ::Mutex.new
      end

      def publish(topic_name, payload = {}, properties = {}, code = Torch.config.transcoder_code)
        properties = Torch.config.default_message_properties.merge properties.dup
        encoded    = Torch::Transcoder.encode payload, properties, code
        get_or_set(topic_name).write encoded
      end

      def stop
        debug 'Shutting down ...'
        @producers.values.each { |p| p.terminate }
        @producers.clear
        debug 'Shut down ...'
      end

      alias :shutdown :stop

      def stopped?
        @producers.size == 0
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

    end

    extend self

    def publisher
      @publisher ||= Publisher.new
    end

    def publish(topic_name, payload = {}, properties = {})
      publisher.publish topic_name, payload, properties
    end

    publisher

    processes.add :publisher

  end
end