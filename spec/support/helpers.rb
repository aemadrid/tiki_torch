require 'rspec/expectations'

module TestingHelpers

  class LogLines
    attr_reader :all

    def initialize
      @all = ThreadSafe::Array.new
    end

    def clear
      @all.clear
    end

    def add(msg)
      @all << msg
    end

    def wait_for_size(nr, timeout = 15)
      start_time = Time.now
      last_time  = start_time + timeout
      while @all.size < nr && Time.now < last_time
        sleep 0.05
      end
      Time.now - start_time
    end

    alias :<< :add
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
    end
    Tiki::Torch.logger.level = Logger::DEBUG if ENV['DEBUG'] == 'true'
    Tiki::Torch.start_polling
    Tiki::Torch.consumer_broker.consumers.each { |x| clear_consumer x }
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
    uri = URI "http://#{known_nsq_host}:#{known_nsq_port}/channel/empty?topic=#{consumer.topic}&channel=#{consumer.channel}"
    res = Net::HTTP.post_form uri, {}
    res.code == '200'
  rescue Exception => e
    debug "clear_consumer | could NOT clear #{consumer.name} : #{consumer.topic} : #{consumer.channel} | Exception: #{e.class.name} : #{e.message} ..."
    false
  end

  def known_nsq
    @known_nsq ||= Array(Tiki::Torch.config.nsqd).first
  end

  def known_nsq_host
    known_nsq.split(':').first
  end

  def known_nsq_port
    known_nsq.split(':').last.to_i + 1
  end

  def debug(msg)
    puts msg
  end
end
