module Tiki
  module Torch
    class Config

      include Virtus.model
      include Logging

      attribute :access_key_id, String, default: lambda { |_, _| ENV['AWS_ACCESS_KEY_ID'] }
      attribute :secret_access_key, String, default: lambda { |_, _| ENV['AWS_SECRET_ACCESS_KEY'] }
      attribute :region, String, default: lambda { |_, _| ENV['AWS_REGION'] }
      attribute :sqs_endpoint, String

      attribute :topic_prefix, String, default: 'tiki_torch'
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
      attribute :events_sleep_times, Hash, default: { idle: 1, busy: 0.1, received: 0.1, empty: 0.5, exception: 0.5 }

      def default_message_properties
        @default_message_properties ||= {}
      end

      def to_s
        %{#<T:T:Config access_key_id=#{access_key_id.inspect} region=#{region.inspect}>}
      end

      alias :inspect :to_s

    end

    def self.config
      @config ||= Config.new
    end

    def self.configure
      yield config
    end

    config

    def aws_options
      @aws_options ||= {
        access_key_id:     config.access_key_id,
        secret_access_key: config.secret_access_key,
        region:            config.region,
      }
    end

    def setup_aws(options = {})
      ::Aws.config = aws_options.merge options
    end

  end
end