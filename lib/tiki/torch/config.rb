module Tiki
  module Torch
    class Config

      include Virtus.model
      include Logging

      EVENT_SLEEP_TIMES = { idle: 60, busy: 60, received: 15, empty: 120, exception: 15, poll: 5, max_wait: 5 * 60 }

      attribute :access_key_id, String, default: lambda { |_, _| ENV['AWS_ACCESS_KEY_ID'] }
      attribute :secret_access_key, String, default: lambda { |_, _| ENV['AWS_SECRET_ACCESS_KEY'] }
      attribute :region, String, default: lambda { |_, _| ENV['AWS_REGION'] }
      attribute :sqs_endpoint, String

      attribute :redistat_host, String, default: lambda { |_, _| ENV.fetch 'REDISTAT_HOST', 'localhost' }
      attribute :redistat_port, Integer, default: lambda { |_, _| ENV.fetch('REDISTAT_PORT', '6379').to_i }
      attribute :redistat_db, Integer, default: lambda { |_, _| ENV.fetch('REDISTAT_DB', '15').to_i }

      attribute :prefix, String, default: 'tiki_torch'
      attribute :channel, String, default: 'events'

      attribute :default_delay, Integer, default: 0 # DelaySeconds
      attribute :max_size, Integer, default: 262144 # MaximumMessageSize
      attribute :retention_period, Integer, default: 345600 # MessageRetentionPeriod
      attribute :policy, String, default: nil # Policy
      attribute :receive_delay, Integer, default: 0 # ReceiveMessageWaitTimeSeconds
      attribute :visibility_timeout, Integer, default: 60 # VisibilityTimeout

      attribute :use_dlq, Boolean, default: false
      attribute :dlq_postfix, String, default: 'dlq'
      attribute :max_attempts, Integer, default: 10

      attribute :event_pool_size, Integer, default: lambda { |_, _| Concurrent.processor_count }
      attribute :transcoder_code, String, default: 'yaml'
      attribute :events_sleep_times, Hash, default: EVENT_SLEEP_TIMES

      def default_message_properties
        @default_message_properties ||= {}
      end

      def to_s
        %{#<T:T:Config access_key_id=#{access_key_id.inspect} region=#{region.inspect}>}
      end

      alias :inspect :to_s

    end

    def config
      @config ||= Config.new
    end

    def configure
      yield config
    end

    def aws_options
      {
        access_key_id:     config.access_key_id,
        secret_access_key: config.secret_access_key,
        region:            config.region,
      }
    end

    def setup_aws(options = {})
      ::Aws.config = aws_options.merge options
    end

    def redistat_options
      {
        host:        config.redistat_host,
        port:        config.redistat_port,
        db:          config.redistat_db,
        thread_safe: true,
      }
    end

    def setup_redistat(options = {})
      ::Redistat.connect redistat_options.merge options
    end

    config

  end
end