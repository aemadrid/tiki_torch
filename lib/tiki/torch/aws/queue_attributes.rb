module Tiki
  module Torch
    class AwsQueueAttributes

      extend Forwardable

      ATTR_NAMES = {
        visible_count:      'ApproximateNumberOfMessages',
        invisible_count:    'ApproximateNumberOfMessagesNotVisible',
        visibility_timeout: 'VisibilityTimeout',
        created_at:         'CreatedTimestamp',
        updated_at:         'LastModifiedTimestamp',
        policy:             'Policy',
        max_size:           'MaximumMessageSize',
        retention_period:   'MessageRetentionPeriod',
        arn:                'QueueArn',
        delayed_count:      'ApproximateNumberOfMessagesDelayed',
        default_delay:      'DelaySeconds',
        receive_delay:      'ReceiveMessageWaitTimeSeconds',
        redrive_policy:     'RedrivePolicy',
      }

      attr_reader :attributes
      def_delegators :@attributes,
                     :ApproximateNumberOfMessages, :ApproximateNumberOfMessagesNotVisible, :VisibilityTimeout,
                     :CreatedTimestamp, :LastModifiedTimestamp, :Policy, :ApproximateNumberOfMessagesDelayed,
                     :DelaySeconds, :ReceiveMessageWaitTimeSeconds, :RedrivePolicy

      def self.from_result(result)
        new result.attributes
      end

      def initialize(attributes)
        @attributes = attributes
      end

      def get(name)
        if (full_name = ATTR_NAMES[name])
          attributes[full_name]
        else
          attributes[name.to_s]
        end
      end

      alias :[] :get

      def visible_count
        get('ApproximateNumberOfMessages').to_i
      end

      def invisible_count
        get('ApproximateNumberOfMessagesNotVisible').to_i
      end

      def visibility_timeout
        get('VisibilityTimeout').to_i
      end

      def created_at
        get('CreatedTimestamp').nil? ? nil : DateTime.strptime(get('CreatedTimestamp'), '%s').to_time
      end

      def updated_at
        get('LastModifiedTimestamp').nil? ? nil : DateTime.strptime(get('LastModifiedTimestamp'), '%s').to_time
      end

      def policy
        get('Policy')
      end

      def max_size
        get('MaximumMessageSize').to_i
      end

      def retention_period
        get('MessageRetentionPeriod').to_i
      end

      def arn
        get('QueueArn')
      end

      def delayed_count
        get('ApproximateNumberOfMessagesDelayed').to_i
      end

      def default_delay
        get('DelaySeconds').to_i
      end

      def receive_delay
        get('ReceiveMessageWaitTimeSeconds').to_i
      end

      def redrive_policy
        get('RedrivePolicy')
      end

    end
  end
end

