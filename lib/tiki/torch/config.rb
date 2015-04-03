# -*- encoding: utf-8 -*-
require 'concurrent/utility/processor_count'

module Tiki
  module Torch
    class Config

      include Logging

      attr_accessor :topic_prefix, :nsqd, :nsqlookupd
      attr_accessor :max_in_flight, :discovery_interval, :msg_timeout
      attr_accessor :transcoder_code
      attr_accessor :event_pool_size, :events_sleep_times
      attr_accessor :colorized
      attr_accessor :processor_count, :physical_processor_count

      def initialize(options = {})
        self.topic_prefix       = 'tiki_torch-'
        self.max_in_flight      = 1
        self.discovery_interval = 60
        self.msg_timeout        = 60_000

        self.transcoder_code = 'json'

        self.event_pool_size    = 4
        self.events_sleep_times = { idle: 1, busy: 0.1, empty: 0.5, }

        self.colorized = false

        processor_counter             = Concurrent::ProcessorCounter.new
        self.processor_count          = processor_counter.processor_count
        self.physical_processor_count = processor_counter.physical_processor_count

        options.each { |k, v| send "#{k}=", v }
      end

      def producer_connection_options(topic_name)
        options              = {
          topic: topic_name,
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