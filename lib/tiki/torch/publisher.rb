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
        full_name  = full_topic_name topic_name
        get_or_set(full_name).write encoded
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

      def get_or_set(key)
        res = @mutex.synchronize do
          get(key) || set(key)
        end
        debug_var :res, res
        res
      end

      def get(key)
        @producers[key]
      end

      def set(key)
        @producers[key] = ::Nsq::Producer.new Torch.config.producer_connection_options(key)
      end

      def full_topic_name(name)
        prefix   = Torch.config.topic_prefix
        new_name = name.to_s
        return new_name if new_name.to_s.start_with? prefix

        "#{prefix}#{new_name}"
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