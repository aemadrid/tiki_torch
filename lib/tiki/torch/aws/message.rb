module Tiki
  module Torch
    class AwsMessage

      extend Forwardable

      def_delegators :@client, :sqs

      attr_accessor :client, :queue_url, :queue_name, :data

      def initialize(data, queue)
        self.client     = queue.client
        self.data       = data
        self.queue_url  = queue.url
        self.queue_name = queue.name
      end

      def delete
        sqs.delete_message queue_url:      queue_url,
                           receipt_handle: data.receipt_handle
      end

      def change_visibility(options)
        opts = options.merge(queue_url: queue_url, receipt_handle: data.receipt_handle)
        sqs.change_message_visibility opts
      end

      def visibility_timeout=(timeout)
        sqs.change_message_visibility queue_url:          queue_url,
                                      receipt_handle:     data.receipt_handle,
                                      visibility_timeout: timeout
      end

      def message_id
        data.message_id
      end

      alias :id :message_id

      def short_id
        message_id[0, 3] + message_id[-3, 3]
      end

      def receipt_handle
        data.receipt_handle
      end

      def md5_of_body
        data.md5_of_body
      end

      def body
        data.body
      end

      def attributes
        data.attributes
      end

      def md5_of_message_attributes
        data.md5_of_message_attributes
      end

      def message_attributes
        data.message_attributes || {}
      end

    end
  end

end