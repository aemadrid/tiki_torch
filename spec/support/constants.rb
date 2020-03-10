# frozen_string_literal: true

require 'rubygems'
require 'bundler'

Bundler.require(:default, :development, :test)

require 'tiki_torch'

require 'fake_sqs/test_integration'

SPEC_ROOT = File.dirname File.dirname(File.expand_path(__FILE__))

DEBUG       = ENV['DEBUG'].to_s == 'true'
ON_REAL_SQS = ENV['USE_REAL_SQS'].to_s == 'true'
FOCUSED     = ENV['FOCUS'] == 'true'
PERFORMANCE = ENV['PERFORMANCE'] == 'true'

if ON_REAL_SQS
  TEST_ACCESS_KEY_ID     = ENV['AWS_TEST_ACCESS_KEY_ID'].to_s.strip
  TEST_SECRET_ACCESS_KEY = ENV['AWS_TEST_SECRET_ACCESS_KEY'].to_s.strip
  TEST_REGION            = ENV['AWS_TEST_REGION'].to_s.strip
  TEST_PREFIX            = "test_#{Time.now.strftime('%m%d_%H%M')}"
  TEST_EVENT_SLEEP_TIMES = { idle: 1, busy: 0.5, received: 1, empty: 0.5, exception: 0.5, poll: 1, max_wait: 5 * 60 }.freeze
  raise "Missing ENV['AWS_TEST_ACCESS_KEY_ID']" if TEST_ACCESS_KEY_ID.empty?
  raise "Missing ENV['AWS_TEST_SECRET_ACCESS_KEY']" if TEST_SECRET_ACCESS_KEY.empty?
  raise "Missing ENV['AWS_TEST_REGION']" if TEST_REGION.empty?
else
  TEST_ACCESS_KEY_ID     = 'fake_access_key'
  TEST_SECRET_ACCESS_KEY = 'fake_secret_key'
  TEST_REGION            = 'fake_region'
  TEST_PREFIX            = 'test'
  TEST_EVENT_SLEEP_TIMES = { idle: 0.5, busy: 0.25, received: 0.5, empty: 0.25, exception: 0.25, poll: 0.5 }.freeze
end

FAKE_SQS_DB       = ENV.fetch('FAKE_SQS_DATABASE', ':memory:')
FAKE_SQS_HOST     = ENV.fetch('FAKE_SQS_HOST', '127.0.0.1')
FAKE_SQS_PORT     = ENV.fetch('FAKE_SQS_PORT', Tiki::Torch::Utils.random_closed_port).to_i
FAKE_SQS_ENDPOINT = "http://#{FAKE_SQS_HOST}:#{FAKE_SQS_PORT}"
