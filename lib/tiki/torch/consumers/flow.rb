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
            @stats ||= Stats.new :started, :succeeded, :failed, :responded, :dead
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

          def polling?
            !@stopped
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
            until @stopped
              begin
                if event_pool.ready?
                  debug "event pool is ready, polling : #{event_pool}"
                  msg = poller.pop
                  if msg
                    debug "got msg : #{msg}"
                    event = Event.new msg
                    debug "got event : #{event}, going to process async ..."
                    event_pool.async { process event }
                    sleep_for :received unless @stopped
                  else
                    sleep_for :empty unless @stopped
                  end
                else
                  sleep_for :busy unless @stopped
                end
              rescue Exception => e
                error "Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 5].join("\n  ")}"
                sleep_for :exception unless @stopped
              end
            end
            debug 'Finished running process loop ...'
          end

          def sleep_for(name)
            sleep_time = events_sleep_times[name]
            debug "going to sleep on #{name} for #{sleep_time} secs ..."
            sleep sleep_time
          end

          def process(event)
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
