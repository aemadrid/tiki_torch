unless Object.const_defined? :SPEC_HELPER_LOADED

  require_relative './support/constants'
  require_relative './support/helpers'
  Dir.glob("#{SPEC_ROOT}/support/consumers/**/*.rb").map { |path| require path }

  RSpec.configure do |c|
    c.include TestingHelpers

    c.filter_run focus: true if FOCUSED

    c.filter_run_excluding performance: true unless PERFORMANCE

    if ON_REAL_SQS
      c.filter_run_excluding on_fake_sqs: true
    else
      c.filter_run_excluding on_real_sqs: true
    end

    c.mock_with :rspec do |mocks|
      mocks.verify_partial_doubles = true
    end

    c.before(:suite) do
      TestingHelpers.delete_queues
      TestingHelpers.setup_fake_sqs
      TestingHelpers.setup_torch
      TestingHelpers.setup_redis_connection
    end

    c.after(:suite) do
      TestingHelpers.stop_fake_sqs
    end

  end

  SPEC_HELPER_LOADED = true
end