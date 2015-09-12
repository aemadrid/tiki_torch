module Tiki
  module Torch
    class Node < Consumer

      class << self

        attr_writer :node_host, :node_name, :node_topic_name

        def default_topic_name
          "node.#{Utils.host}.#{Utils.random_name}"
        end

        def responses
          @responses ||= Concurrent::Hash.new
        end

      end

      responses
      consumes default_topic_name, channel: 'node_events'

      def process
        parent_id = event.properties[:request_message_id]
        raise 'Missing request_message_id property' if parent_id.nil?

        debug '[%s] received (%s) %s' % [parent_id[-4..-1], payload.class.name, payload.inspect]
        self.class.responses[parent_id] = payload
        debug '[%s] We have now %i responses' % [parent_id[-4..-1], self.class.responses.size]
        nil
      end

    end

    class RequestTimedOutError < RuntimeError

      attr_reader :timeout, :message_id, :topic_name, :payload, :properties

      def initialize(timeout, message_id, topic_name, payload, properties)
        @timeout    = timeout
        @message_id = message_id
        @topic_name = topic_name
        @payload    = payload
        @properties = properties
      end

    end

    extend self

    def request(topic_name, payload = {}, properties = {})
      raise RuntimeError, 'The consumer broker is not polling' unless Tiki::Torch.consumer_broker.running?

      mid     = properties[:request_message_id] || SecureRandom.hex
      timeout = properties.delete(:timeout) || 60

      properties[:request_message_id] ||= mid
      properties[:respond_to]         = Node.full_topic_name

      Node.debug "#{req_lbl(mid)} requesting | #{topic_name} | (#{payload.class.name}) #{payload.inspect}"
      publisher.publish topic_name, payload, properties

      Concurrent::Future.execute { respond_to_request(topic_name, payload, properties, timeout) }
    end

    private

    def respond_to_request(topic_name, payload, properties, timeout)
      mid          = properties[:request_message_id]
      timeout_time = Time.now + timeout
      received     = false
      cnt          = 0
      value        = nil

      while Time.now < timeout_time
        cnt += 1
        Node.debug "#{req_lbl(mid)} (#{cnt}) waiting for response ..." if cnt % 10 == 0
        break unless Node.polling?
        if Node.responses.key?(mid)
          value = Node.responses.delete mid
          Node.debug "#{req_lbl(mid)} got response | (#{value.class.name}) #{value.inspect}"
          received = true
          break
        end
        sleep 0.1
      end

      unless received
        Node.debug "#{req_lbl(mid)} never received response, timing out ..."
        raise RequestTimedOutError.new(timeout, mid, topic_name, payload, properties)
      end

      value
    end

    def req_lbl(message_id)
      '[M:%s|R:%i:%s]' % [message_id[-4..-1], Node.responses.size, Node.responses.keys.sort.join(',')]
    end

  end
end