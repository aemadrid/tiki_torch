require 'virtus'
require 'concurrent'
require 'concurrent/utility/processor_counter'

module Tiki
  module Torch
    class Config

      include Virtus.model
      include Logging

      attribute :nsqlookupd, Array[String], default: lambda { |_, _| [ENV['NSLOOKUPD_ADDRESS']].compact }
      attribute :nsqd, Array[String], default: lambda { |config, _| config.safe_default_nsqd_address }

      attribute :topic_prefix, String, default: 'tiki_torch-'
      attribute :max_in_flight, Integer, default: 10
      attribute :discovery_interval, Integer, default: 60
      attribute :msg_timeout, Integer, default: 60_000

      attribute :back_off_strategy, Class
      attribute :max_attempts, Integer, default: 100
      attribute :back_off_time_unit, Integer, default: 3_000

      attribute :transcoder_code, String, default: 'json'

      attribute :event_pool_size, Integer, default: lambda { |_, _| Concurrent.processor_count }
      attribute :events_sleep_times, Integer, default: { idle: 1, busy: 0.1, received: 0.1, empty: 0.5, exception: 0.5 }
      attribute :processor_count, Integer, default: lambda { |_, _| Concurrent.processor_count }

      def producer_connection_options(topic_name)
        options              = { topic: topic_name }
        options[:nsqlookupd] = nsqlookupd unless nsqlookupd.empty?
        options[:nsqd]       = nsqd unless nsqd.empty?
        options
      end

      def default_message_properties
        @default_message_properties ||= {}
      end

      def safe_default_nsqd_address
        return nil unless nsqlookupd.empty?
        [ENV['NSQD_ADDRESS']] unless ENV['NSQD_ADDRESS'].nil?
        ['localhost:4150']
      end

    end

    def self.config
      @config ||= Config.new
    end

    def self.configure
      yield config
    end

    config

  end
end