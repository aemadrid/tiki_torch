ON_REAL_SQS = ENV['USE_REAL_SQS'].to_s == 'true'

if ON_REAL_SQS
  TEST_ACCESS_KEY_ID     = ENV['AWS_TEST_ACCESS_KEY_ID'].to_s.strip
  TEST_SECRET_ACCESS_KEY = ENV['AWS_TEST_SECRET_ACCESS_KEY'].to_s.strip
  TEST_REGION            = ENV['AWS_TEST_REGION'].to_s.strip
  TEST_PREFIX            = "test_#{Time.now.strftime('%m%d-%H%M')}"
  raise "Missing ENV['AWS_TEST_ACCESS_KEY_ID']" if TEST_ACCESS_KEY_ID.empty?
  raise "Missing ENV['AWS_TEST_SECRET_ACCESS_KEY']" if TEST_SECRET_ACCESS_KEY.empty?
  raise "Missing ENV['AWS_TEST_REGION']" if TEST_REGION
else
  TEST_ACCESS_KEY_ID     = 'fake_access_key'
  TEST_SECRET_ACCESS_KEY = 'fake_secret_key'
  TEST_REGION            = 'fake_region'
  TEST_PREFIX            = 'test'
end
