unless Object.const_defined? :SPEC_HELPER_LOADED

  require 'rubygems'
  require 'bundler'

  Bundler.require(:default, :development, :test)

  require 'tiki_torch'

  require 'support/helpers'
  require 'support/consumers'

  RSpec.configure do |config|
    config.include TestingHelpers

    config.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = true
    end

    config.before(:each, integration: true) do
      $lines    = TestingHelpers::LogLines.new
      $messages = TestingHelpers::Messages.new
      TestingHelpers.setup_torch
    end

    config.after(:each, integration: true) do
      TestingHelpers.take_down_torch
    end

  end

  SPEC_HELPER_LOADED = true
end