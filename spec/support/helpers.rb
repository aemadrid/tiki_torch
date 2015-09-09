require 'rspec/expectations'

module TestingHelpers

  class LogLines
    attr_reader :all

    def initialize
      @all = Concurrent::Array.new
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

  def setup_vars
    $all_consumers     ||= Tiki::Torch.consumer_broker.consumers.dup
    $current_consumers = [$consumers].flatten.compact
    $current_consumers = [$consumer].compact if $current_consumers.empty?
    $current_consumers = $all_consumers.dup if $current_consumers.empty?
    $current_consumers << Tiki::Torch::Node
  end

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
    Tiki::Torch.consumer_broker.consumer_registry.clear
    $current_consumers.each { |x| Tiki::Torch.consumer_broker.register_consumer x }
    Tiki::Torch.start_polling
  end

  def take_down_torch
    Tiki::Torch.shutdown
    Tiki::Torch.consumer_broker.consumer_registry.clear
    $current_consumers.each { |x| clear_consumer x }
  end

  def take_down_vars
    $consumers         = nil
    $consumer          = nil
    $current_consumers = nil
  end

  def wait_for(secs, msg = nil)
    debug "[#{Time.now}] Waiting for #{secs} #{msg ? "to #{msg} " : nil}..."
    sleep secs
    yield if block_given?
    true
  end

  def clear_consumer(consumer)
    [delete_channel(consumer), delete_topic(consumer)]
  end

  def delete_channel(consumer)
    uri = URI "http://#{known_nsq_host}:#{known_nsq_port}/channel/delete" +
                "?topic=#{consumer.full_topic_name}" +
                "&channel=#{consumer.channel}"
    res = Net::HTTP.post_form uri, {}
    res.code == '200'
  rescue Exception => e
    debug "delete_channel | could NOT clear #{consumer.name} : #{consumer.topic} : #{consumer.channel} | Exception: #{e.class.name} : #{e.message} ..."
    false
  end

  def delete_topic(consumer)
    uri = URI "http://#{known_nsq_host}:#{known_nsq_port}/topic/delete" +
                "?topic=#{consumer.full_topic_name}"
    res = Net::HTTP.post_form uri, {}
    res.code == '200'
  rescue Exception => e
    debug "delete_topic | could NOT clear #{consumer.name} : #{consumer.topic} : #{consumer.channel} | Exception: #{e.class.name} : #{e.message} ..."
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
