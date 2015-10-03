unless Object.const_defined? :SPEC_HELPER_LOADED

  require 'rubygems'
  require 'bundler'

  Bundler.require(:default, :development, :test)

  require 'tiki_torch'

  require 'support/helpers'
  require 'support/consumers'

  RSpec.configure do |c|
    c.include TestingHelpers

    c.filter_run focus: true if ENV['FOCUS'] == 'true'
    c.filter_run_excluding performance: true unless ENV['PERFORMANCE'] == 'true'

    c.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = true
    end

    c.before(:each, integration: true) do
      $lines = TestingHelpers::LogLines.new
      TestingHelpers.setup_vars
      TestingHelpers.setup_torch
    end

    c.after(:each, integration: true) do
      TestingHelpers.take_down_torch
    end

    c.after(:context, integration: true) do
      TestingHelpers.take_down_vars
    end

    c.after(:suite) do
      secs = Tiki::Torch.config.msg_timeout / 1000.0 + 1
      Tiki::Torch::Utils.wait_for secs
      TestingHelpers.clear_all_consumers
    end

  end

  SPEC_HELPER_LOADED = true
end