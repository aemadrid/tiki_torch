module Tiki
  module Torch
    class ConsumerBroker

      include Logging
      extend Forwardable

      attr_reader :consumer

      def_delegators :@consumer,
                     :name,
                     :config, :topic, :topic_prefix, :channel,
                     :queue_name, :dead_letter_queue_name, :visibility_timeout, :retention_period,
                     :max_attempts, :event_pool_size, :events_sleep_times

      def_delegators :@manager, :client

      def initialize(consumer, manager)
        @consumer = consumer
        @manager  = manager
      end

      def status
        @status ||= :stopped
      end

      def starting?
        status == :starting
      end

      def running?
        status == :running
      end

      def stopping?
        status == :stopping
      end

      def stopped?
        status == :stopped
      end

      def stats
        @stats ||= Stats.new :started, :succeeded, :failed, :responded, :dead, :requeued
      end

      def busy_size
        @event_pool.try(:busy_size) || 0
      end

      def lbl(cnt = nil)
        "[#{@consumer.name.gsub('Consumer', '')}:#{status}#{cnt ? ":#{cnt}" : ''}]"
      end

      def start
        unless stopped?
          debug "cannot start on #{status} ..."
          return false
        end

        debug "#{lbl} starting consumer ..."
        @status = :starting
        build_consumer
        stats
        start_poller
        start_process_loop
        @status = :running
        debug "#{lbl} running consumer!"
        @status
      rescue Exception => e
        puts "Exception thrown: #{e.class.name} : #{e.message}\n  #{e.backtrace[0,5].join("\n  ")}"
      end

      def stop
        unless running?
          debug "cannot stop on #{status} ..."
          return false
        end

        debug "#{lbl} stopping consumer ..."
        @status = :stopping
        stop_process_loop
        stop_poller
        @status = :stopped
        debug "#{lbl} stopped consumer!"
        @status
      end

      def to_s
        %{#<T:T:ConsumerBroker consumer=#{@consumer} manager=#{@manager}>}
      end

      alias :inspect :to_s

      private

      def process_loop
        debug "#{lbl} Started running process loop ..."
        @event_pool = Tiki::Torch::ThreadPool.new :events, event_pool_size
        debug "#{lbl} got @event_pool : #{@event_pool.inspect}"
        cnt = 0
        while running?
          cnt += 1
          begin
            debug "#{lbl(cnt)} calling poll_and_process_message while running?:#{running?} ..."
            poll_and_process_message
            debug "#{lbl(cnt)} called poll_and_process_message while running?:#{running?} ..."
          rescue Exception => e
            debug "#{lbl(cnt)} exception in poll and process message ..."
            error "Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 5].join("\n  ")}"
            sleep_for :exception, "#{e.class.name}/#{e.message}"
          end
        end
        debug "#{lbl} Finished running process loop ..."
      end

      def build_consumer
        debug "build consumer | @already_built : #{@already_built} ..."
        return false if @already_built

        debug 'building consumer ...'
        ConsumerBuilder.new(@consumer, @manager).build
        @already_built = true
      end

      def start_poller
        debug 'starting poller ...'
        @poller = Tiki::Torch::ConsumerPoller.new consumer, client
        debug "#{lbl} @poller : #{@poller}"
      end

      def start_process_loop
        debug 'starting process loop ...'
        @process_loop_thread = Thread.new do
          begin
            process_loop
          rescue Exception => e
            error "Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 10].join("\n  ")}"
          end
        end
      end

      def poll_and_process_message
        debug "#{lbl} starting poll and process message ..."
        if @event_pool.try(:ready?)
          @polling = true
          debug "#{lbl} event pool is ready, polling : #{@event_pool}"
          messages = @poller.pop @event_pool.ready_size, 1
          debug "#{lbl} messages : got #{messages.size} messages back ..."
          if messages.size > 0
            messages.each do |msg|
              sleep_for(:busy, @event_pool.try(:tag)) until @event_pool.try(:ready?)
              debug "#{lbl} msg : (#{msg.class.name}) ##{msg.id}"
              process_message msg
            end
          else
            sleep_for :received, @event_pool.try(:tag)
          end
          @polling = false
        else
          sleep_for :busy, @event_pool.try(:tag)
        end
        debug "#{lbl} ended poll and process message ..."
      rescue Exception => e
        error "#{lbl} Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 5].join("\n  ")}"
        sleep_for :exception, "#{e.class.name}/#{e.message}"
      end

      def process_message(msg)
        if msg
          debug "#{lbl} got msg : (#{msg.class.name}) ##{msg.id}"
          event = Event.new msg
          debug "#{lbl} got event : (#{event.class.name}) ##{event.short_id}, going to process async ..."
          sleep_for :busy, @event_pool.try(:tag) until @event_pool.try(:ready?)
          debug "#{lbl} sending event ##{event.short_id} to event pool #{@event_pool}..."
          @event_pool.async { process_event event }
          sleep_for :received, @event_pool.try(:tag)
        else
          sleep_for :empty, @event_pool.try(:tag)
        end
      rescue Exception => e
        error "#{lbl} Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 5].join("\n  ")}"
        sleep_for :exception, "#{e.class.name}/#{e.message}"
      end

      def process_event(event)
        debug "processing event ##{event.id} ..."
        instance = @consumer.new event, self
        debug_var :instance, instance

        begin
          debug 'starting ...'
          instance.on_start
          debug 'processing ...'
          result = instance.process
          debug 'succeeding ...'
          instance.on_success result
        rescue => e
          debug 'failing ...'
          instance.on_failure e
        ensure
          debug 'ending ...'
          instance.on_end
        end
      rescue Exception => e
        error "Exception thrown: #{e.class.name} : #{e.message}\n  #{e.bactrace[0, 5].join("\n  ")}"
      end

      def sleep_for(name, msg = nil)
        return nil if stopped?

        sleep_time = Torch.config.events_sleep_times[name]
        debug "#{lbl} going to sleep on #{name}#{msg ? " (#{msg})" : ''}for #{sleep_time} secs ..."
        sleep sleep_time
      rescue Exception => e
        error "Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 5].join("\n  ")}"
      end

      def stop_process_loop
        stop_event_pool
        stop_process_loop_thread
      end

      def stop_event_pool
        debug "#{lbl} stopping event pool ..."
        if @event_pool
          cnt = 0
          until @event_pool.free?
            cnt += 1
            debug "[#{cnt}] event #{@event_pool} is not free"
            sleep 0.25
          end
          debug "#{lbl} shutting down #{@event_pool} ..."
          @event_pool.shutdown 3
          @event_pool = nil
        end
        debug "#{lbl} stopped event pool!"
      end

      def stop_process_loop_thread
        debug "#{lbl} stopping loop thread ..."
        if @process_loop_thread
          debug "#{lbl} joining loop thread ..."
          @process_loop_thread.join
          debug "#{lbl} terminating loop thread ..."
          @process_loop_thread.terminate
        end
        debug "#{lbl} stopped loop thread!"
      end

      def stop_poller
        debug "#{lbl} stopping poller ..."
        @poller.close
        @poller = nil
        debug "#{lbl} stopped poller ..."
      end

    end
  end
end