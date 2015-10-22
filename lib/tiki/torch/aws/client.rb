module Tiki
  module Torch
    class AwsClient

      include Logging

      attr_writer :sqs

      def sqs
        @sqs ||= ::Aws::SQS::Client.new aws_client_options(:sqs_endpoint)
      end

      VALID_QUEUE_RX = /^[\w_-]{1,80}$/i

      def queues(prefix = Tiki::Torch.config.topic_prefix)
        sqs.list_queues(queue_name_prefix: prefix).
          queue_urls.sort.
          map { |x| AwsQueue.from_url x, self }
      end

      def queue(name)
        check_valid_queue_name! name
        res = get_queue(name) || find_queue(name) || create_queue(name)
        raise "Could not obtain queue [#{name}]" unless res
        res
      end

      def to_s
        %{#<T:T:AwsClient>}
      end

      alias :inspect :to_s

      private

      def aws_client_options(key)
        options = { region: Torch.aws_options[:region] }
        if (explicit = Torch.config[key])
          options[:endpoint] = explicit
        elsif (from_env = ENV["AWS_#{key.to_s.upcase}"])
          options[:endpoint] = from_env
        end
        options
      end

      def check_valid_queue_name!(name)
        message = 'Can only include alphanumeric characters, hyphens, or underscores. 1 to 80 in length'
        raise ArgumentError, message unless name =~ VALID_QUEUE_RX
      end

      def create_queue(name)
        resp  = sqs.create_queue queue_name: name
        queue = AwsQueue.from_url resp.queue_url, self
        cache_queue name, queue
      rescue Aws::SQS::Errors::QueueNameExists
        get_queue(name) || find_queue(name)
      end

      def find_queue(name)
        found = AwsQueue.from_name name, self
        return nil unless found

        cache_queue name, found
      end

      def known_queues
        @known_queues ||= Concurrent::Hash.new
      end

      def get_queue(name)
        known_queues[name]
      end

      def cache_queue(name, queue)
        known_queues[name] = queue
      end

    end

    extend self

    attr_writer :client

    def client
      @client ||= AwsClient.new
    end

    client.send(:known_queues)

  end
end