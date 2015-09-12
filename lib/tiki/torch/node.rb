require 'socket'

module Tiki
  module Torch
    class Node < Consumer

      class << self

        attr_writer :node_host, :node_name, :node_topic_name

        def node_host
          Socket.gethostname
        end

        def node_topic_name
          @node_topic_name ||= "node.#{node_host}.#{random_node_name}"
        end

        def random_node_name(syllables = 4, sep = 4)
          consonants = %w{ b c d f g j k l m n p r s t z }
          vowels     = %w{ a e i o u }
          list       = syllables.times.map { consonants.sample + vowels.sample }.join.split('')
          list.each_slice(sep).map { |x| x.join }.join('-')
        end

        def responses
          @responses ||= Concurrent::Hash.new
        end

      end

      responses
      consumes node_topic_name, channel: 'node_events'

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

    def node
      Node
    end

    node.responses

    def request(topic_name, payload = {}, properties = {})
      raise RuntimeError, 'The consumer broker is not polling' unless Tiki::Torch.consumer_broker.running?

      mid     = properties[:request_message_id] || SecureRandom.hex
      timeout = properties.delete(:timeout) || 60

      properties[:request_message_id] ||= mid
      properties[:respond_to]         = node.full_topic_name

      node.debug "#{req_lbl(mid)} requesting | #{topic_name} | (#{payload.class.name}) #{payload.inspect}"
      publisher.publish topic_name, payload, properties

      Concurrent::Future.execute { respond_to_request(topic_name, payload, properties, timeout) }
    end

    private

    def respond_to_request(topic_name, payload, properties, timeout)
      mid          = properties[:request_message_id]
      timeout_time = Time.now + timeout
      received     = false
      cnt          = 0

      while Time.now < timeout_time
        cnt += 1
        node.debug "#{req_lbl(mid)} (#{cnt}) waiting for response ..." if cnt % 10 == 0
        break unless node.polling?
        if node.responses.key?(mid)
          value = node.responses.delete mid
          node.debug "#{req_lbl(mid)} got response | (#{value.class.name}) #{value.inspect}"
          received = true
          break
        end
        sleep 0.1
      end

      unless received
        node.debug "#{req_lbl(mid)} never received response, timing out ..."
        raise RequestTimedOutError.new(timeout, mid, topic_name, payload, properties)
      end

      value
    end

    def req_lbl(message_id)
      '[M:%s|R:%i:%s]' % [message_id[-4..-1], node.responses.size, node.responses.keys.sort.join(',')]
    end

  end
end