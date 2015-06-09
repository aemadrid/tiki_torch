require 'rspec/expectations'

module TestingHelpers

  class LogLines

    attr_reader :all

    def initialize
      @all = []
    end

    def clear
      @all.clear
    end

    def add(msg)
      @all << msg
    end

    alias :<< :add

  end


  class Messages

    Message = Struct.new(:consumer, :id, :payload, :properties, :attempts, :thread_id, :result) do

      def to_s
        %{[M|#{consumer}#{id.to_s[0, 6]}|#{payload.inspect}|#{properties}|#{thread_id}]}
      end

      alias :inspect :to_s

    end

    attr_reader :all

    def initialize
      @all = ThreadSafe::Array.new
    end

    def size
      all.size
    end

    def add(options = {})
      msg = Message.new options[:consumer],
                        options[:id],
                        options[:payload],
                        options[:properties],
                        options[:attempts],
                        options[:thread_id],
                        options[:result]
      all << msg
    end

    def add_event(class_name, event, result = nil)
      add consumer:   class_name,
          id:         event.message_id,
          payload:    event.payload,
          properties: event.properties,
          attempts:   event.attempts,
          thread_id:  Thread.current.object_id,
          result:     result
    end

    def consumers_names
      all.map { |x| x.consumer }
    end

    def message_ids
      all.map { |x| x.id }
    end

    def payloads
      all.map { |x| x.payload }
    end

    def properties
      all.map { |x| x.properties }
    end

    def attempts
      all.map { |x| x.attempts }
    end

    def thread_ids
      all.map { |x| x.thread_id }
    end

    def results
      all.map { |x| x.result }
    end

    def consumer_count(class_name)
      all.count { |x| x.consumer == class_name }
    end

    def to_s
      "Messages : (#{all.size})\n> " + all.map { |x| x.to_s }.join("\n > ")
    end

    alias :inspect :to_s

  end

  extend self

  def setup_torch
    Tiki::Torch.configure do |c|
      if (lkd = ENV['NSLOOKUPD_ADDRESS'])
        c.nsqlookupd = lkd
      elsif (nsd = ENV['NSQD_ADDRESS'])
        c.nsqd = nsd
      else
        c.nsqd = 'localhost:4150'
      end
      c.colorized = false
    end
    Tiki::Torch.logger.level = Logger::DEBUG if ENV['DEBUG'] == 'true'
    Tiki::Torch.start_polling
  end

  def take_down_torch
    Tiki::Torch.shutdown
  end

  def wait_for(secs, msg = nil)
    debug "[#{Time.now}] Waiting for #{secs} #{msg ? "to #{msg} " : nil}..."
    sleep secs
    yield if block_given?
    true
  end

  def clear_consumer(consumer)
    uri = URI "http://#{known_nsq_host}:4151/channel/empty?topic=#{consumer.topic}&channel=#{consumer.channel}"
    # debug "clear_consumer | uri : #{uri}"
    res = Net::HTTP.post_form uri, {}
    # debug "clear_consumer | res : (#{res.class.name}) #{res.inspect}"
    if res.code == '200'
      debug "clear_consumer | cleared : #{consumer.name} : #{consumer.topic} : #{consumer.channel} ..."
      true
    else
      debug "clear_consumer | could NOT clear #{consumer.name} : #{consumer.topic} : #{consumer.channel} ..."
      false
    end
  end

  def known_nsq_host
    Array(Tiki::Torch.config.nsqd).first.split(':').first
  end

  def debug(msg)
    puts msg
  end
end
