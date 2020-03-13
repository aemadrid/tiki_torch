# frozen_string_literal: true

module Tiki
  module Torch
    class SerialPoller
      include Logging

      attr_reader :consumer, :queue, :stats

      def initialize(consumer, client = Torch.client)
        @consumer = consumer
        @queue    = client.queue consumer.queue_name
        @stats    = nil
      end

      def run_once
        show_stats
        return false unless stats[:available] > 0

        messages = poll
        process_messages messages
      rescue Exception => e
        log_exception e
      end

      def to_s
        %{#<T:T:SerialPoller consumer=#{consumer.name.inspect}>}
      end

      alias :inspect :to_s

      private

      def config
        Torch.config
      end

      def poll
        opts = {
          max_number_of_messages:  config.serial_qty,
          wait_time_seconds:       config.serial_timeout,
          visibility_timeout:      config.serial_visibility,
          message_attribute_names: ['All']
        }
        queue.receive_messages opts
      rescue Exception => e
        log_exception e
      end

      def process_messages(messages)
        return unless messages.size.positive?

        info format('%50.50s : found %i message/s', consumer.queue_name, messages.size)
        successful = messages.count { |message| process_message message }
        info format('%50.50s : successfully processed %i/%i message/s', consumer.queue_name, successful, messages.size)
        successful
      end

      def process_message(message)
        event = Consumers::Event.new message
        process_event event
      rescue Exception => e
        log_exception e
        return false
      end

      def process_event(event)
        instance = consumer.new event, self

        begin
          instance.on_start
          result = instance.process
          instance.on_success result
          info format('%50.50s : success : %s', consumer.queue_name, event.short_id)
          success = true
        rescue Exception => e
          info format('%50.50s : failed  : %s', consumer.queue_name, event.short_id)
          log_exception e
          instance.on_failure e
          success = false
        ensure
          instance.on_end
          return success
        end
      end

      def show_stats
        refresh_stats
        label = format('%s - %s', consumer.name, consumer.queue_name)[-50, 50]
        info format('%50.50s : %4i / %2i / %2i', label, @stats[:available], @stats[:hidden], @stats[:delayed])
      end

      def refresh_stats
        attrs  = queue.attributes
        @stats = {
          available: attrs['ApproximateNumberOfMessages'].to_i,
          hidden:    attrs['ApproximateNumberOfMessagesNotVisible'].to_i,
          delayed:   attrs['ApproximateNumberOfMessagesDelayed'].to_i
        }
      end

      def show_banner
        info " [ #{consumer.name} : #{consumer.topic} ] ".center(120, '-')
      end
    end
  end
end
