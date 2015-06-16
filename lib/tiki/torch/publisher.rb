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

      def publish(topic_name, payload = {}, properties = {})
        code = properties.delete(:transcoder_code) || Torch.config.transcoder_code

        full_name  = full_topic_name topic_name
        nsqlookupd = properties.delete(:nsqlookupd) || Torch.config.nsqlookupd
        nsqd       = properties.delete(:nsqd) || Torch.config.nsqd

        properties = Torch.config.default_message_properties.dup.
          merge(message_id: SecureRandom.hex).
          merge(properties)
        encoded    = Torch::Transcoder.encode payload, properties, code

        res = get_or_set(full_name, nsqlookupd, nsqd).write encoded
        debug_var :res, res
        res
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

      def key_for_options(name, nsqlookupd, nsqd)
        parts = []
        parts << "t:#{name}"
        parts << "l:#{[nsqlookupd].flatten.map { |x| x.to_s }.join(':')}" unless nsqlookupd.nil?
        parts << "n:#{[nsqd].flatten.map { |x| x.to_s }.join(':')}" unless nsqd.nil?
        parts.join('|')
      end

      def get_or_set(full_name, nsqlookupd, nsqd)
        key = key_for_options full_name, nsqlookupd, nsqd
        res = @mutex.synchronize do
          get(key) || set(key, full_name, nsqlookupd, nsqd)
        end
        debug_var :res, res
        res
      end

      def get(key)
        @producers[key]
      end

      def set(key, full_name, nsqlookupd, nsqd)
        options              = Torch.config.producer_connection_options full_name
        options[:nsqlookupd] = nsqlookupd unless nsqlookupd.nil?
        options[:nsqd]       = nsqd unless nsqd.nil?

        @producers[key] = ::Nsq::Producer.new options
      end

      def full_topic_name(name)
        prefix   = Torch.config.topic_prefix
        new_name = name.to_s
        return new_name if new_name.start_with? prefix

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