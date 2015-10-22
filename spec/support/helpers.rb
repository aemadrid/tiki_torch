require 'rspec/expectations'
require 'rspec/core/shared_context'
require 'json'
require 'socket'
require 'timeout'

module TestingHelpers

  extend RSpec::Core::SharedContext

  class LogLines

    include Tiki::Torch::Logging

    attr_reader :all

    def initialize
      @all = Concurrent::Array.new
    end

    def sorted
      all.sort { |a, b| a <=> b }
    end

    def clear
      @all.clear
    end

    def add(msg)
      @all << msg
    end

    def wait_for_size(nr, timeout = 15)
      start_time  = Time.now
      last_time   = start_time + timeout
      cnt, status = 0, nil
      loop do
        cnt    += 1
        status = if @all.size >= nr
                   :enough
                 elsif Time.now >= last_time
                   :timed_out
                 else
                   :keep
                 end
        break unless status == :keep
        debug 'cnt : %i | status : %s | size: %i/%i | left : %.2fs' % [cnt, status, @all.size, nr, last_time - Time.now] if cnt % 10 == 0
        sleep 0.05
      end
      took = last_time - Time.now
      debug 'cnt : %i | status : %s | size: %i/%i | took : %.2fs (%.2fr/s)' % [cnt, status, @all.size, nr, took, cnt / took.to_f]
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

  module Consumer

    private

    def sleep_if_necessary(period_time = 0.1, touch_event = false)
      secs = payload.is_a?(Hash) ? payload[:sleep_time].to_f : nil
      if secs
        wake_up = Time.now + secs
        debug "[#{event.short_id}]> Sleeping until #{wake_up} (#{secs}s) ..."
        while Time.now < wake_up
          sleep period_time
          event.touch if touch_event
        end
      else
        debug "[#{event.short_id}]> no need to sleep ..."
      end
    end

  end

  let(:config) { Tiki::Torch.config }
  let(:consumer) { described_class }
  let(:consumers) { [consumer] }
  let(:polling_pattern) { %r{#{consumers.map { |x| x.name }.join('|') }} }
  let(:manager_client) { Tiki::Torch.client }
  let(:manager_options) { Tiki::Torch.config }
  let(:manager) { Tiki::Torch::Manager.new manager_client, manager_options }
  let(:queue_name) { 'fake-sqs-queue' }
  let(:queue) { Tiki::Torch.client.queue queue_name }

  extend self

  def debug(msg)
    puts msg
  end

  def bnr(msg, chr = '=')
    debug " [ #{msg} ] ".center(120, chr)
  end

  def time_it(msg = nil, chr = '=')
    start_time = Time.now
    bnr "#{msg} - start", chr if msg
    yield
    took = Time.now - start_time
    bnr "#{msg} - end - #{took}s", chr if msg
    took
  end

  def random_closed_port(start = 3000, limit = 1000)
    port, closed = nil, false
    until closed
      port   = start + rand(limit) + 1
      closed = !port_open?(port)
    end
    port
  end

  def port_open?(port, ip = '127.0.0.1', seconds = 0.5)
    Timeout::timeout(seconds) do
      begin
        TCPSocket.new(ip, port).close
        debug "port_open? : #{ip} : #{port} : true"
        true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        debug "port_open? : #{ip} : #{port} : false"
        false
      end
    end
  rescue Timeout::Error
    false
  end

  FAKE_SQS_DB       = ENV.fetch('FAKE_SQS_DATABASE', ':memory:')
  FAKE_SQS_HOST     = ENV.fetch('FAKE_SQS_HOST', '127.0.0.1')
  FAKE_SQS_PORT     = ENV.fetch('FAKE_SQS_PORT', random_closed_port).to_i
  FAKE_SQS_ENDPOINT = "http://#{FAKE_SQS_HOST}:#{FAKE_SQS_PORT}"

  def setup_fake_sqs
    if ON_REAL_SQS
      debug ' [ Running from a real SQS queue ] '.center(120, '=')
    elsif $fake_sqs
      # Already setup fake SQS
    else
      debug " [ Running from a fake SQS queue : #{FAKE_SQS_ENDPOINT} ] ".center(120, '=')
      $fake_sqs = FakeSQS::TestIntegration.new database:     FAKE_SQS_DB,
                                               sqs_endpoint: FAKE_SQS_HOST,
                                               sqs_port:     FAKE_SQS_PORT
    end
  end

  def start_fake_sqs
    return false if ON_REAL_SQS
    # debug '>>> starting fake sqs ...'
    $fake_sqs.start
  end

  def stop_fake_sqs
    return false if ON_REAL_SQS
    # debug '>>> stopping fake sqs ...'
    $fake_sqs.stop
  end


  def config_torch
    Tiki::Torch.configure do |c|
      c.access_key_id     = TEST_ACCESS_KEY_ID
      c.secret_access_key = TEST_SECRET_ACCESS_KEY
      c.region            = TEST_REGION
      c.topic_prefix      = TEST_PREFIX
    end
    Tiki::Torch.logger.level = Logger::DEBUG if ENV['DEBUG'] == 'true'
  end

  def setup_torch
    Tiki::Torch.client.sqs = nil
    Tiki::Torch.setup_aws
  end

  def take_down_torch
    Tiki::Torch.client = nil
  end

  def delete_queues
    return false unless ON_REAL_SQS

    Tiki::Torch.client.queues(TEST_PREFIX).each do |queue|
      debug "> Deleting queue #{queue.name} ..."
      Tiki::Torch.client.sqs.delete_queue queue_url: queue.url
    end
  end

  before(:each) do
    config_torch
  end

  around(:example, integration: true) do |example|
    # debug '>>> starting integration ...'
    $lines = LogLines.new
    start_fake_sqs
    setup_torch
    # debug '>>> running integration ...'
    example.run
    # debug '>>> ending integration ...'
    take_down_torch
    stop_fake_sqs
  end

  around(:example, polling: true) do |example|
    # debug '>>> starting polling ...'
    manager.start_polling polling_pattern
    # debug '>>> running polling ...'
    example.run
    # debug '>>> ending polling ...'
    manager.stop_polling
  end

end
