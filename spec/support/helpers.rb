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

    def to_s
      %{#<#{self.class.name} size=#{@all.size} all=#{@all.inspect}>}
    end

    alias :inspect :to_s

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
    Tiki::Torch.logger.level       = Logger::DEBUG if ENV['DEBUG'] == 'true'
    Tiki::Torch::Node.topic        = 'node-test'
    Tiki::Torch.config.msg_timeout = 5_000 # ms
    Tiki::Torch.consumer_broker.consumer_registry.clear
    $current_consumers.each { |x| Tiki::Torch.consumer_broker.register_consumer x }
    Tiki::Torch.start_polling
  end

  def take_down_torch
    Tiki::Torch.shutdown
    Tiki::Torch.consumer_broker.consumer_registry.clear
    $current_consumers.each { |x| clear_consumer x } if $current_consumers
  end

  def take_down_vars
    $consumers         = nil
    $consumer          = nil
    $current_consumers = nil
  end

  def wait_for(secs, &blk)
    ::Tiki::Torch::Utils.wait_for(secs){ blk.call if blk }
  end

  def clear_all_consumers
    $all_consumers.each { |x| clear_consumer x }
  end

  def clear_consumer(consumer)
    delete_nsqd_channel consumer
    delete_nsqd_topic consumer
    delete_nsqadmin_topic consumer
  end

  def delete_nsqd_channel(consumer)
    http_command :nsqd_chn_emp,
                 "http://#{known_nsq_host}:#{known_nsq_port}/channel/empty",
                 topic:   consumer.full_topic_name,
                 channel: consumer.channel
    http_command :nsqd_chn_del,
                 "http://#{known_nsq_host}:#{known_nsq_port}/channel/delete",
                 topic:   consumer.full_topic_name,
                 channel: consumer.channel
  end

  def delete_nsqd_topic(consumer)
    http_command :nsqd_top_emp,
                 "http://#{known_nsq_host}:#{known_nsq_port}/topic/empty",
                 topic: consumer.full_topic_name
    http_command :nsqd_top_del,
                 "http://#{known_nsq_host}:#{known_nsq_port}/topic/delete",
                 topic: consumer.full_topic_name
  end

  def delete_nsqadmin_topic(consumer)
    http_command :nsqa_top_emp,
                 "http://#{known_nsq_host}:#{known_nsqadmin_port}/empty_topic",
                 topic: consumer.full_topic_name
    http_command :nsqa_top_del,
                 "http://#{known_nsq_host}:#{known_nsqadmin_port}/delete_topic",
                 topic: consumer.full_topic_name
  end

  def http_command(type, url, data = {})
    qry = URI.encode data.map { |k, v| "#{k}=#{v}" }.join("&")
    url = "#{url}?#{qry}" unless qry.empty?
    uri = URI url
    res = Net::HTTP.post_form uri, {}
    # puts "HTTP #{type} | #{res.code} | #{res.body} | #{uri}"
    res.code == '200'
  rescue Exception => e
    debug "Exception: #{e.class.name} : #{e.message} |  #{e.backtrace[0, 5].join("\n  ")}"
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

  def known_nsqadmin_port
    known_nsq.split(':').last.to_i + 21
  end

  def debug(msg)
    puts msg
  end
end
