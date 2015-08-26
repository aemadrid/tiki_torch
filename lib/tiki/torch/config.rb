require 'virtus'
require 'concurrent'
require 'concurrent/utility/processor_counter'

module Tiki
  module Torch
    class Config

      include Virtus.model
      include Logging

      attr_accessor :topic_prefix
      attr_accessor :nsqd
      attr_accessor :nsqlookupd
      attr_accessor :max_in_flight
      attr_accessor :discovery_interval
      attr_accessor :msg_timeout
      attr_accessor :max_attempts
      attr_accessor :back_off_time_unit
      attr_accessor :transcoder_code
      attr_accessor :event_pool_size
      attr_accessor :events_sleep_times
      attr_accessor :colorized
      attr_accessor :processor_count
      attr_accessor :physical_processor_count

      def initialize(options = {})
        self.topic_prefix       = 'tiki_torch-'
        self.max_in_flight      = 10
        self.discovery_interval = 60
        self.msg_timeout        = 60_000

        self.max_attempts       = 100
        self.back_off_time_unit = 3_000 # In milliseconds

        self.transcoder_code = 'json'

        self.processor_count          = self.class.processor_counter.processor_count
        self.physical_processor_count = self.class.processor_counter.physical_processor_count
        self.event_pool_size          = self.class.processor_counter.processor_count

        self.events_sleep_times = { idle: 1, busy: 0.1, empty: 0.5, }

        self.colorized = false

        options.each { |k, v| send "#{k}=", v }
      end

      def producer_connection_options(topic_name)
        options              = { topic: topic_name }
        options[:nsqlookupd] = nsqlookupd unless nsqlookupd.nil?
        options[:nsqd]       = nsqd unless nsqd.nil?
        options
      end

      def default_message_properties
        @default_message_properties ||= {}
      end

      def self.processor_counter
        @processor_counter ||= ::Concurrent::Utility::ProcessorCounter.new
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