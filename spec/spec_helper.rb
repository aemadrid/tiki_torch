unless Object.const_defined? :SPEC_HELPER_LOADED

  require 'rubygems'
  require 'bundler'

  Bundler.require(:default, :development, :test)

  require 'tiki_torch'

  SPEC_ROOT = File.dirname File.expand_path(__FILE__)

  require 'fake_sqs/test_integration'
  require 'support/helpers'
  Dir.glob("#{SPEC_ROOT}/support/consumers/**/*.rb").map { |path| require path }

  RSpec.configure do |c|
    c.include TestingHelpers

    c.filter_run focus: true if ENV['FOCUS'] == 'true'
    c.filter_run_excluding performance: true unless ENV['PERFORMANCE'] == 'true'
    c.filter_run_excluding on_real_sqs: true unless TestingHelpers.on_real_sqs

    c.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = true
    end

    c.before(:suite) do
      puts '>>> starting suite ...'
      TestingHelpers.setup_fake_sqs
    end

    c.after(:suite) do
      puts '>>> ending suite ...'
      TestingHelpers.delete_queues
    end

  end

  SPEC_HELPER_LOADED = true
end