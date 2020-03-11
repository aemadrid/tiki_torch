module Tiki
  module Torch
    class ConsumerBroker

      include Logging
      extend Forwardable

      attr_reader :consumer

      def_delegators :@consumer,
                     :name,
                     :config, :topic, :prefix, :channel,
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
          poll_and_process_messages
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
        @process_loop_thread = Thread.new { process_loop }
      end

      POLL_AND_PROCESS_ACTIONS = [
        :check_if_pool_is_ready,
        :check_if_need_to_poll,
        :poll_for_messages,
        :deal_with_no_messages,
        :process_messages
      ]

      def poll_and_process_messages
        debug "#{lbl} starting poll and process message ..."
        POLL_AND_PROCESS_ACTIONS.each_with_index do |name, idx|
          break if stopping?
          action, detail = send name
          debug "#{lbl} ##{idx + 1}/#{POLL_AND_PROCESS_ACTIONS.size} #{name} : #{action} #{detail ? " : #{detail}" : ''}"
          case action
            when :empty, :busy
              sleep_for action, @event_pool.try(:tag)
              break
          end
        end

      rescue Exception => e
        error "#{lbl} Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 5].join("\n  ")}"
        sleep_for :exception, "#{e.class.name}/#{e.message}"
      end

      def check_if_pool_is_ready
        @event_pool.try(:ready?) ? :continue : :busy
      end

      def check_if_need_to_poll
        return [:continue, 'not polled yet'] if @polled_at.nil?
        return [:continue, 'received some last'] if @received.to_i > 0
        return [:continue, 'must check since'] if max_wait_passed?

        [:empty, 'neither received all nor published since']
      end

      def max_wait_passed?
        Time.now >= next_poll_time
      end

      def next_poll_time
        return Time.now if @polled_at.nil?

        @polled_at + randomize_secs(events_sleep_times[:max_wait].to_f, 1, 3)
      end

      def poll_for_messages
        timeout    = events_sleep_times[:poll].to_f
        @requested = @event_pool.ready_size

        if @requested > 0
          @messages  = @poller.pop @requested, timeout
          @received  = @messages.size
          @polled_at = Time.now
          @consumer.pop_results @requested, @received, timeout
          [:continue, "got #{@received}/#{@requested}"]
        else
          @messages  = []
          @received  = 0
          [:continue, "got bad requested size [#{@requested}]"]
        end
      end

      def deal_with_no_messages
        @messages.size > 0 ? [:continue, 'got messages to process'] : [:empty, 'got no messages']
      end

      def process_messages
        @messages.each_with_index do |msg, idx|
          debug "#{lbl} ##{idx + 1}/#{@received} | msg : (#{msg.class.name}) ##{msg.id}"
          process_message msg
        end
        @messages = []
        sleep_for :received, @event_pool.try(:tag)
        [:processed, "processed #{@received}/#{@requested}"]
      end

      def process_message(msg)
        event = Consumers::Event.new msg
        debug "#{lbl} got event : (#{event.class.name}) ##{event.short_id}, going to process async ..."
        @event_pool.async { process_event event }
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
        rescue Exception => e
          debug 'failing ...'
          instance.on_failure e
        ensure
          debug 'ending ...'
          instance.on_end
        end
      end

      def sleep_for(name, msg = nil)
        return nil if stopped?

        time = events_sleep_times[name].to_f
        if time.nil? || time.to_f < 0.1
          debug '%s not going to sleep on %s%s [%s:%s] ...' % [lbl, name, (msg ? " (#{msg})" : ''), time.class.name, time.inspect]
          return false
        end

        rand_time = randomize_secs time, 2, 1
        debug '%s going to sleep on %s%s for %.2f secs (max: %.2f secs) ...' % [lbl, name, (msg ? " (#{msg})" : ''), rand_time, time]
        sleep rand_time
      end

      def randomize_secs(seconds, base_size, diff_size)
        total = base_size.to_f + diff_size
        base  = seconds.to_f * base_size.to_f / total
        diff  = seconds.to_f * diff_size.to_f / total * rand(101.0).to_f / 100.0
        (base + diff).round(2)
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
