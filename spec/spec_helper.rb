unless Object.const_defined? :SPEC_HELPER_LOADED

  require 'rubygems'
  require 'bundler'

  Bundler.require(:default, :development, :test)

  require 'tiki_torch'

  require 'support/helpers'
  require 'support/consumers'

  RSpec.configure do |config|
    config.include TestingHelpers

    config.filter_run focus: true if ENV['FOCUS'] == 'true'

    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = true
    end

    config.before(:each, integration: true) do
      $lines = TestingHelpers::LogLines.new
      TestingHelpers.setup_vars
      TestingHelpers.setup_torch
    end

    config.after(:each, integration: true) do
      TestingHelpers.take_down_torch
    end

    config.after(:context, integration: true) do
      TestingHelpers.take_down_vars
    end

    config.after(:suite) do
      secs = Tiki::Torch.config.msg_timeout / 1000.0 + 1
      puts "Waiting for #{secs} secs ..."
      Tiki::Torch::Utils.wait_for secs
      puts "Waited for #{secs} secs ..."
      TestingHelpers.clear_all_consumers
      puts "cleared all consumers ..."
    end

  end

  SPEC_HELPER_LOADED = true
end