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

    def size
      @all.size
    end

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
    ($all_consumers || []).each { |x| clear_consumer x }
  end

  def clear_consumer(consumer)
    delete_nsqd_channel consumer
    delete_nsqd_topic consumer
    delete_nsqadmin_topic consumer
  end

  def delete_nsqd_channel(consumer)
    http_command :nsqd_chn_emp, topic: consumer.full_topic_name, channel: consumer.channel
    http_command :nsqd_chn_del, topic: consumer.full_topic_name, channel: consumer.channel
    http_command :nsqd_chn_emp, topic: consumer.full_dlq_topic_name, channel: consumer.channel
    http_command :nsqd_chn_del, topic: consumer.full_dlq_topic_name, channel: consumer.channel
  end

  def delete_nsqd_topic(consumer)
    http_command :nsqd_top_emp, topic: consumer.full_topic_name
    http_command :nsqd_top_del, topic: consumer.full_topic_name
    http_command :nsqd_top_emp, topic: consumer.full_dlq_topic_name
    http_command :nsqd_top_del, topic: consumer.full_dlq_topic_name
  end

  def delete_nsqadmin_topic(consumer)
    http_command :nsqa_top_emp, topic: consumer.full_topic_name
    http_command :nsqa_top_del, topic: consumer.full_topic_name
    http_command :nsqa_top_emp, topic: consumer.full_dlq_topic_name
    http_command :nsqa_top_del, topic: consumer.full_dlq_topic_name
  end

  def http_command_urls(type)
    @http_command_urls ||= {
      nsqd_stats:   "http://#{known_nsq_host}:#{known_nsq_port}/stats?format=json",
      nsqd_chn_emp: "http://#{known_nsq_host}:#{known_nsq_port}/channel/empty",
      nsqd_chn_del: "http://#{known_nsq_host}:#{known_nsq_port}/channel/delete",
      nsqd_top_emp: "http://#{known_nsq_host}:#{known_nsq_port}/topic/empty",
      nsqd_top_del: "http://#{known_nsq_host}:#{known_nsq_port}/topic/delete",
      nsqa_top_emp: "http://#{known_nsq_host}:#{known_nsqadmin_port}/empty_topic",
      nsqa_top_del: "http://#{known_nsq_host}:#{known_nsqadmin_port}/delete_topic",
    }
    @http_command_urls[type]
  end

  def http_command(type, data = {})
    url = http_command_urls(type)
    qry = URI.encode data.map { |k, v| "#{k}=#{v}" }.join("&")
    url = "#{url}?#{qry}" unless qry.empty?
    uri = URI url
    res = Net::HTTP.post_form uri, {}
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

  def nsq_stats
    url = http_command_urls :nsqd_stats
    uri = URI url
    res = Net::HTTP.get_response uri
    raise 'could not obtain NSQ stats' unless res.code == '200'
    MultiJson.load res.body, symbolize_keys: true
  end

  def nsq_topic(name)
    stats = nsq_stats
    topics = stats[:data][:topics]
    topics.select { |h| h[:topic_name] == name }.first
  end

  def expect_nsq_topic_count(name, exp_cnt)
    topic = nsq_topic(name)
    if topic
      actual_cnt = topic[:message_count]
      expect(actual_cnt).to eq(exp_cnt), "expected topic #{name} to have #{exp_cnt} messages but found #{actual_cnt}"
    else
      expect(0).to eq(exp_cnt), "expected topic #{name} to have #{exp_cnt} messages but found 0"
    end
  end

  def debug(msg)
    puts msg
  end

  def time_it
    start_time = Time.now
    yield
    Time.now - start_time
  end

  def varied_secs(max = 60, min = 5)
    rand(max - min + 1) + min
  end
end
