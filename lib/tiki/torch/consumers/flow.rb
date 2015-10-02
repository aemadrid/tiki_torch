module Tiki
  module Torch
    class Consumer
      module Flow

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods

          attr_reader :poller, :event_pool

          def stats
            @stats ||= Stats.new :started, :succeeded, :failed, :responded, :dead, :requeued
          end

          def busy_size
            event_pool ? event_pool.busy_size : 0
          end

          def start
            debug 'starting ...'

            @poller = Tiki::Torch::ConsumerPoller.new poller_options
            res     = poller.connected?
            debug "connected : #{res}"

            debug 'setting up stats'
            stats

            @stopped = false

            debug 'starting process loop ...'
            @process_loop_thread = Thread.new { process_loop }

            debug 'started ...'
          end

          def stop
            debug 'stopping ...'
            @stopped = true
            poller.close
            @poller = nil
            Thread.new { stop_events }
            debug 'sent stop message ...'
          end

          def stopped?
            @stopped
          end

          def polling?
            @polling
          end

          def stop_events
            debug 'stopping events ...'
            if event_pool
              cnt = 0
              until event_pool.free?
                cnt += 1
                debug "[#{cnt}] event #{event_pool} is not free"
                sleep 0.25
              end
              debug "shutting down #{event_pool} ..."
              event_pool.shutdown
              @event_pool = nil
              @process_loop_thread.join
              @process_loop_thread.terminate
            end
            debug 'done stopping events ...'
          end

          def poller_options
            {
              topic:              full_topic_name,
              channel:            channel,
              nsqd:               nsqd,
              nsqlookupd:         nsqlookupd,
              max_in_flight:      max_in_flight,
              discovery_interval: discovery_interval,
              msg_timeout:        msg_timeout,
            }.tap do |options|
              options.delete_if { |_, v| v.is_a?(Array) && v.empty? }
            end
          end

          def process_loop
            debug 'Started running process loop ...'
            @event_pool = Tiki::Torch::ThreadPool.new(:events, event_pool_size)
            debug "got @event_pool : #{@event_pool.inspect}"
            poll_and_process_message until @stopped
            debug 'Finished running process loop ...'
          end

          def poll_and_process_message
            if event_pool
              if event_pool.ready?
                @polling = true
                debug "event pool is ready, polling : #{event_pool}"
                msg = poller ? poller.pop : nil
                process_message msg
                @polling = false
              else
                sleep_for :busy, event_pool.tag
              end
            else
              sleep_for :busy, 'no event pool present'
            end
          rescue Exception => e
            error "Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 5].join("\n  ")}"
            sleep_for :exception, "#{e.class.name}/#{e.message}"
          end

          def process_message(msg)
            if msg
              debug "got msg : (#{msg.class.name}) ##{msg.id}"
              event = Event.new msg
              debug "got event : (#{event.class.name}) ##{event.short_id}, going to process async ..."
              if event_pool && event_pool.ready?
                debug "sending event ##{event.short_id} to event pool #{event_pool}..."
                event_pool.async { process_event event }
                sleep_for :received
              else
                debug "event pool was not there or ready to process, requeueing event ##{event.short_id} ..."
                event.requeue
                stats.increment :requeued
              end
            else
              sleep_for :empty
            end
          rescue Exception => e
            error "Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 5].join("\n  ")}"
            sleep_for :exception, "#{e.class.name}/#{e.message}"
          end

          def sleep_for(name, msg = nil)
            return nil if @stopped

            sleep_time = events_sleep_times[name]
            debug "going to sleep on #{name}#{msg ? " (#{msg})" : ''}for #{sleep_time} secs ..."
            sleep sleep_time
          rescue Exception => e
            error "Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 5].join("\n  ")}"
          end

          def process_event(event)
            instance = new event
            debug_var :instance, instance

            begin
              instance.on_start
              result = instance.process
              instance.on_success result
              instance.on_rpc_response result
            rescue => e
              instance.on_failure e
            ensure
              instance.on_end
            end
          end

        end

        def stats
          self.class.stats
        end

      end
    end
  end
end
