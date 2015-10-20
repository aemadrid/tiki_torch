module Tiki
  module Torch
    class AwsClient

      include Logging

      attr_writer :sqs

      def sqs
        @sqs ||= ::Aws::SQS::Client.new aws_client_options(:sqs_endpoint)
      end

      def queues(prefix = Tiki::Torch.config.topic_prefix)
        sqs.list_queues(queue_name_prefix: prefix).
          queue_urls.sort.
          map { |x| AwsQueue.from_url x, self }
      end

      def queue(name)
        type = nil

        unless type
          debug "[#{name}] checking known queues | #{known_queues.size} : #{known_queues.keys.join(', ')}"
          q    = known_queues[name]
          type = :known if q
        end

        unless type
          debug "[#{name}] getting queue from server ..."
          q    = get_queue(name)
          type = :found if q
        end

        unless type
          debug "[#{name}] creating queue on server ..."
          q    = create_queue(name)
          type = :created if q
        end

        type ||= :missing

        # q = known_queues[name] || get_queue(name) || create_queue(name)
        puts "[#{name}] #{type} | (#{q.class.name}) #{q ? q.inspect : 'MISSING'}"
        raise "Could not obtain queue [#{name}]" unless q
        q
      end

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

      def create_queue(name)
        resp = sqs.create_queue queue_name: name
        debug_var :resp, resp
        debug "known_queues : 1 | #{known_queues.size} : #{known_queues.keys.join(', ')}"
        known_queues[name] = AwsQueue.from_url resp.queue_url, self
        debug "known_queues : 2 | #{known_queues.size} : #{known_queues.keys.join(', ')}"
        known_queues[name]
      rescue Aws::SQS::Errors::QueueNameExists
        known_queues[name] || get_queue(name)
      end

      def get_queue(name)
        found = AwsQueue.from_name name, self
        return nil unless found

        known_queues[name] = found
      end

      def known_queues
        @known_queues ||= Concurrent::Hash.new
      end

    end

    extend self

    attr_writer :client

    def client
      @client ||= AwsClient.new
    end

    client

  end
end