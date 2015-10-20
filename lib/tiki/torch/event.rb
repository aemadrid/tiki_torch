module Tiki
  module Torch
    class Event

      extend Forwardable
      include Logging

      attr_reader :message, :payload, :properties

      def initialize(message)
        @message = message
        @deleted = false
      end

      delegate [:body, :message_id, :short_id, :delete, :visibility_timeout=] => :message
      alias :id :message_id

      def payload
        decoded.first
      end

      def properties
        decoded.last
      end

      delegate [:[]] => :payload

      def parent_message_id
        properties[:parent_message_id] || ' ' * 32
      end

      alias :parent_id :parent_message_id

      def parent_short_id
        parent_message_id[0, 3] + parent_message_id[-3, 3]
      end

      def finished?
        !!@deleted
      end

      def finish
        return false if finished?

        debug "Finishing ##{short_id} ..."
        res      = message.delete
        @deleted = true
      end

      def to_s
        attrs = {
          message_id: message_id,
          body:       body.size,
          payload:    payload.class.name,
        }
        "#<#{self.class.name} #{attrs.map { |k, v| "#{k}=#{v.inspect}" }.join(', ')}>"
      end

      alias :inspect :to_s

      private

      def decoded
        @_decoded ||= Torch::Transcoder.decode message.body
      end

    end
  end
end