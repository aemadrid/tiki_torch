require 'rspec/expectations'
require 'rspec/core/shared_context'
require 'json'

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
  let(:manager) { Tiki::Torch::Manager.new }
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

  def setup_fake_sqs
    if ON_REAL_SQS
      debug ' [ Running from a real SQS queue ] '.center(120, '=')
    else
      if $fake_sqs
        # Already setup fake SQS
      else
        debug " [ Running from a fake SQS queue : #{FAKE_SQS_ENDPOINT} ] ".center(120, '=')
        $fake_sqs = FakeSQS::TestIntegration.new database:     FAKE_SQS_DB,
                                                 sqs_endpoint: FAKE_SQS_HOST,
                                                 sqs_port:     FAKE_SQS_PORT
      end
      Tiki::Torch.config.sqs_endpoint = FAKE_SQS_ENDPOINT
    end
  end

  def start_fake_sqs
    return false if ON_REAL_SQS
    # debug '>>> starting fake sqs ...'
    $fake_sqs.start
  end

  def stop_fake_sqs
    return false if ON_REAL_SQS
    return false unless $fake_sqs
    # debug '>>> stopping fake sqs ...'
    $fake_sqs.stop
  end

  def setup_fake_dynamo
    return false if $started_fake_dynamo
    Tiki::Torch.config.dynamo_endpoint = FAKE_DYNAMO_ENDPOINT

    FileUtils.mkdir_p File.dirname(FAKE_DYNAMO_DB_PATH)
    FakeDynamo::Storage.instance.init_db FAKE_DYNAMO_DB_PATH
    FakeDynamo::Logger.setup FAKE_DYNAMO_LOG_LEVEL

    if FAKE_DYNAMO_COMPACT
      FakeDynamo::Storage.instance.load_aof
      FakeDynamo::Storage.instance.compact!
    end

    FakeDynamo::Storage.instance.load_aof
    at_exit { stop_fake_dynamo }
    $started_fake_dynamo = true
  end

  def start_fake_dynamo
    setup_fake_dynamo
    return false if $fake_dynamo_thread

    $fake_dynamo_thread = Thread.new do
      FakeDynamo::Server.run!(port: FAKE_DYNAMO_PORT, bind: FAKE_DYNAMO_HOST) do |server|
        if server.respond_to?('config') && server.config.respond_to?('[]=')
          server.config[:AccessLog] = []
        end
      end
    end
  end

  def reset_fake_dynamo
    FakeDynamo::Storage.instance.reset
    FakeDynamo::Storage.instance.load_aof
  end

  def stop_fake_dynamo
    return false unless $stopped_fake_dynamo
    return false unless $fake_dynamo_thread

    FakeDynamo::Storage.instance.shutdown
    FakeDynamo::Storage.instance.reset
    $fake_dynamo_thread.exit
    $fake_dynamo_thread = nil
    File.rm FAKE_DYNAMO_DB_PATH

    $stopped_fake_dynamo = true
  end

  def config_torch
    puts ' [ Configuring torch ... ] '.center(120, '-')
    Tiki::Torch.configure do |c|
      c.access_key_id      = TEST_ACCESS_KEY_ID
      c.secret_access_key  = TEST_SECRET_ACCESS_KEY
      c.region             = TEST_REGION
      c.prefix             = TEST_PREFIX
      c.events_sleep_times = TEST_EVENT_SLEEP_TIMES
    end
    Tiki::Torch.logger.level = Logger::DEBUG if ENV['DEBUG'] == 'true'
  end

  def setup_torch
    config_torch
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

  def setup_redis_connection
    Redistat.connect host: REDIS_HOST, port: REDIS_PORT, db: REDIS_DB, thread_safe: true
    clear_redis
  end

  def clear_redis
    Redistat.redis.flushdb
  end

  before(:each) do
    config_torch
  end

  around(:example, integration: true) do |example|
    debug '>>> starting integration ...'
    $lines = LogLines.new
    start_fake_sqs
    setup_torch
    debug '>>> running integration ...'
    example.run
    debug '>>> ending integration ...'
    take_down_torch
    stop_fake_sqs
  end

  around(:example, polling: true) do |example|
    debug '>>> starting polling ...'
    manager.start_polling polling_pattern
    debug '>>> running polling ...'
    example.run
    debug '>>> ending polling ...'
    manager.stop_polling
    clear_redis
  end

  around(:example, dynamo: true) do |example|
    debug '>>> starting dynamo ...'
    setup_fake_dynamo
    start_fake_dynamo
    debug '>>> running dynamo ...'
    example.run
    debug '>>> resetting dynamo ...'
    reset_fake_dynamo
  end

end

begin
  require 'simplecov'
  SimpleCov.start
  SimpleCov.at_exit { SimpleCov.result.format! }
rescue LoadError
  puts 'SimpleCov not available, skipping coverage ...'
end
