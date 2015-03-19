# -*- encoding: utf-8 -*-

require 'multi_json'
require 'celluloid'

module Tiki
  module Torch
    class Config

      include Logging

      attr_accessor :topic_prefix, :nsqd, :nsqlookupd
      attr_accessor :max_in_flight, :discovery_interval, :msq_timeout
      attr_accessor :pool_size, :event_pool_size
      attr_accessor :poll_for_events, :events_idle_sleep_time, :events_busy_sleep_time
      attr_accessor :colorized

      def initialize(options = {})
        self.topic_prefix       = 'tiki_torch-'
        self.max_in_flight      = 1
        self.discovery_interval = 60
        self.msq_timeout        = 60_000

        self.event_pool_size = Celluloid.cores
        self.poll_for_events = false

        self.events_idle_sleep_time = 1
        self.events_busy_sleep_time = 0.1

        self.colorized = false

        options.each { |k, v| send "#{k}=", v }
      end

      def consumer_connection_options(topic_name, channel_name)
        options              = {
            topic:              "#{topic_prefix}#{topic_name}",
            channel:            channel_name.to_s,
            max_in_flight:      max_in_flight,
            discovery_interval: discovery_interval,
            msq_timeout:        msq_timeout,
        }
        options[:nsqlookupd] = nsqlookupd unless nsqlookupd.nil?
        options[:nsqd]       = nsqd unless nsqd.nil?
        options
      end

      def producer_connection_options(topic_name)
        options              = {
            topic: "#{topic_prefix}#{topic_name}",
        }
        options[:nsqlookupd] = nsqlookupd unless nsqlookupd.nil?
        options[:nsqd]       = nsqd unless nsqd.nil?
        options
      end

      def default_message_properties
        @default_message_properties ||= {
            message_id: SecureRandom.hex,
        }
      end

      def payload_encoding_handler
        @payload_encoding_handler ||= lambda do |payload, properties|
          MultiJson.dump payload:    payload || {},
                         properties: default_message_properties.merge(properties || {})
        end
      end

      def payload_decoding_handler
        @payload_decoding_handler ||= lambda do |str|
          hsh = MultiJson.load str, symbolize_keys: true
          [hsh[:payload], hsh[:properties]]
        end
      end

      private

      def topic_name(name)
        name.to_s.gsub(/[^\.a-zA-Z0-9_-]/, '')[0, 32]
      end

    end

    def self.config
      @config ||= Config.new
    end

    config

  end
end