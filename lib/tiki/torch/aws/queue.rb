module Tiki
  module Torch
    class AwsQueue

      include Logging
      extend Forwardable

      attr_accessor :name, :client, :url

      def_delegators :client, :sqs

      def self.from_url(url, client)
        new url.split('/').last, url, client
      end

      def self.from_name(name, client)
        url = client.sqs.get_queue_url(queue_name: name).queue_url
        new name, url, client
      rescue Aws::SQS::Errors::NonExistentQueue
        return nil
      end

      def initialize(name, url, client)
        self.name   = name
        self.url    = url
        self.client = client
      end

      def attributes(*names)
        names = names.flatten.map { |x| ATTR_NAMES[x] || x }.compact
        names << 'All' if names.empty?
        result = retryable_sqs_cmd(:get_queue_attributes, queue_url: url, attribute_names: names)
        result ? AwsQueueAttributes.new(result) : nil
      end

      def attributes=(options = {})
        retryable_sqs_cmd(:set_queue_attributes, queue_url: url, attribute_names: options)
      end

      def attribute(name)
        attributes[name]
      end

      alias :[] :attribute

      def visibility_timeout
        attribute(:visibility_timeout).to_i
      end

      def delete_messages(options = {})
        retryable_sqs_cmd :delete_message_batch, options.merge(queue_url: url)
      end

      def send_message(options = {})
        options = sanitize_message!(options).merge(queue_url: url)
        retryable_sqs_cmd :send_message, options
      end

      def send_messages(options = {})
        sanitized = sanitize_messages!(options).merge(queue_url: url)
        retryable_sqs_cmd :send_message_batch, sanitized
      end

      def receive_messages(options = {})
        options = options.merge queue_url: url
        retryable_sqs_cmd(:receive_message, options).
          messages.
          map { |m| Torch::AwsMessage.new(m, self) }
      end

      def to_s
        %{#<T:T:AwsQueue name=#{name.inspect}>}
      end

      alias :inspect :to_s

      private

      def sanitize_message!(options = {})
        options = sanitize_message!(message_body: options) if options.is_a? String
        validate_message! options
      end

      def sanitize_messages!(options)
        options = case
                    when options.is_a?(Array)
                      { entries: options.map.with_index { |msg, idx| sanitize_message!(msg).merge(id: idx.to_s) } }
                    when options.is_a?(Hash)
                      options
                  end

        validate_messages! options
      end

      def validate_messages!(options = {})
        options[:entries].map { |m| validate_message! m }
        options
      end

      def validate_message!(options = {})
        fail ArgumentError, "The message must be a Hash and you passed a #{options.class.name}" unless options.is_a? Hash
        body = options[:message_body]
        fail ArgumentError, "The message body must be a String and you passed a #{body.class.name}" unless body.is_a? String
        options
      end

      def retryable_sqs_cmd(cmd, *args)
        debug "cmd : #{cmd} | args : #{args.inspect}"
        tries  ||= 3
        result = sqs.send cmd, *args
      rescue Aws::SQS::Errors::QueueNameExists,
        Aws::SQS::Errors::NonExistentQueue => e
        if (tries -= 1) > 0
          error "Exception (tries left: #{tries}): #{e.class.name} : #{e.message}"
          retry
        else
          error "Exception (failing): #{e.class.name} : #{e.message}"
        end
      else
        info "success! result: #{result.class.name} #{result.inspect}"
        result
      end

    end
  end
end