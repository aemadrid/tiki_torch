require 'set'

module Tiki
  module Torch
    class ConsumerBroker

      include Logging

      class << self

        def consumer_registry
          @consumer_registry ||= Set.new
        end

        alias :consumers :consumer_registry

        def register_consumer(consumer_class)
          # debug_var :consumer_registry, consumer_registry
          # debug_var :consumer_class, consumer_class
          consumer_registry.add consumer_class
        end

        def start
          @running = true
          consumer_registry.each do |consumer_class|
            debug "starting #{consumer_class.name} : #{consumer_class.topic} : #{consumer_class.channel} ..."
            consumer_class.start
          end
        end

        def stop
          return false unless @running

          @running = false
          debug 'stopping consumers ...'
          consumer_registry.each do |consumer_class|
            debug "stopping #{consumer_class.name} T:#{consumer_class.topic} C:#{consumer_class.channel} ..."
            consumer_class.stop
          end
          debug 'done telling consumers to stop ...'
        end

        alias :shutdown :stop

        def running?
          !!@running
        end

        def stopped?
          cnt = busy_consumers_count
          res = !running? && cnt == 0
          debug "res : (#{res.class.name}) #{res} | #{cnt > 0 ? "still #{cnt}" : 'no'} busy consumers | cnt : #{cnt} | @running : #{@running}"
          res
        end

        def busy_consumers_count
          consumer_registry.inject(0) { |count, consumer_class| count + consumer_class.busy_size }
        end

      end
    end

    extend self

    def start_polling
      ConsumerBroker.start
    end

    def stop_polling
      ConsumerBroker.stop
    end

    def consumer_broker
      ConsumerBroker
    end

    processes.add :consumer_broker

  end
end