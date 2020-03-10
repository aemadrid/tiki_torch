# frozen_string_literal: true

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
      cnt = 0
      status = nil
      loop do
        cnt += 1
        status = if @all.size >= nr
                   :enough
                 elsif Time.now >= last_time
                   :timed_out
                 else
                   :keep
                 end
        break unless status == :keep

        if cnt % 10 == 0
          debug format('C : cnt : %i | status : %s | size: %i/%i | left : %.2fs%s', cnt, status, @all.size, nr, last_time - Time.now, "\n#{@all.to_yaml}")
        end
        sleep 0.05
      end
      took = last_time - Time.now
      debug format('F : cnt : %i | status : %s | size: %i/%i | took : %.2fs (%.2fr/s)%s', cnt, status, @all.size, nr, took, cnt / took.to_f, "\n#{@all.to_yaml}")
      Time.now - start_time
    end

    alias << add

    def size
      @all.size
    end

    def to_s
      %(#<#{self.class.name} size=#{@all.size} all=#{@all.inspect}>)
    end

    alias inspect to_s
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
  let(:polling_pattern) { /#{consumers.map(&:name).join('|')}/ }
  let(:manager) { Tiki::Torch::Manager.new }
  let(:queue_name) { 'fake-sqs-queue' }
  let(:queue) { Tiki::Torch.client.queue queue_name }

  module_function

  def debug(msg)
    puts msg if DEBUG
  end

  def bnr(msg, chr = '=')
    debug " [ #{msg} ] ".center(90, chr)
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
      puts ' [ Running from a real SQS queue ] '.center(90, '=')
    else
      unless $fake_sqs
        puts " [ Running from a fake SQS queue : #{FAKE_SQS_ENDPOINT} ] ".center(90, '=')
        $fake_sqs = FakeSQS::TestIntegration.new database: FAKE_SQS_DB,
                                                 sqs_endpoint: FAKE_SQS_HOST,
                                                 sqs_port: FAKE_SQS_PORT
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

  def config_torch
    Tiki::Torch.configure do |c|
      c.access_key_id      = TEST_ACCESS_KEY_ID
      c.secret_access_key  = TEST_SECRET_ACCESS_KEY
      c.region             = TEST_REGION
      c.prefix             = TEST_PREFIX
      c.events_sleep_times = TEST_EVENT_SLEEP_TIMES
    end
    Tiki::Torch.logger.level = DEBUG ? Logger::DEBUG : Logger::INFO
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
      begin
        Tiki::Torch.client.sqs.delete_queue queue_url: queue.url
      rescue Aws::SQS::Errors::NonExistentQueue
        debug "Error: queue #{queue.name} was not found ..."
      end
    end
  end

  before(:each) do
    config_torch
  end

  around(:example, integration: true) do |example|
    debug '>>> starting integration ...'
    $lines = LogLines.new
    debug '>>> starting fake sqs ...'
    start_fake_sqs
    debug '>>> setting up porch ...'
    setup_torch
    debug '>>> starting polling ...'
    manager.start_polling polling_pattern
    debug '>>> running integration ...'
    example.run
    debug '>>> ending integration ...'
    debug '>>> ending polling ...'
    manager.stop_polling
    debug '>>> taking down porch ...'
    take_down_torch
    debug '>>> stopping fake sqs ...'
    stop_fake_sqs
  end

  around(:example, polling: true) do |example|
    debug '>>> running polling ...'
    example.run
  end
end

begin
  require 'simplecov'
  SimpleCov.start
  SimpleCov.at_exit { SimpleCov.result.format! }
rescue LoadError
  puts 'SimpleCov not available, skipping coverage ...'
end
