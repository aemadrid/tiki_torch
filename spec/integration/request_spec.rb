describe 'request and response', integration: true do

  before(:context) { $consumer = AdderConsumer }

  it 'requesting returns a future and in time we get a value' do
    hsh    = { numbers: [1, 2, 3], sleep_time: 2 }
    future = Tiki::Torch.request $consumer.full_topic_name, hsh, timeout: 15

    expect(future).to be_a Concurrent::Future
    expect([:pending, :processing]).to include(future.state)
    expect(future.value(0)).to be_nil

    $lines.wait_for_size 1

    expect(future.state).to eq :fulfilled
    expect(future.value).to eq 6
  end

  it 'requesting returns a future that times out' do
    hsh    = { numbers: [1, 2, 3], sleep_time: 5 }
    future = Tiki::Torch.request $consumer.full_topic_name, hsh, timeout: 2

    expect(future).to be_a Concurrent::Future
    expect([:pending, :processing]).to include(future.state)
    expect(future.value(0)).to be_nil

    sleep 2.5

    expect(future.value).to be_nil
    expect(future.state).to eq :rejected

    reason = future.reason
    expect(reason).to be_a Tiki::Torch::RequestTimedOutError
    expect(reason.timeout).to eq 2
    expect(reason.message_id).to be_a String
    expect(reason.topic_name).to eq $consumer.full_topic_name
    expect(reason.payload).to eq hsh
    expect(reason.properties).to be_a Hash
  end

  it 'multiple requests concurrently' do
    futures    = 3.times.map do |nr|
      hsh = { numbers: [1, nr], sleep_time: 1 }
      Tiki::Torch.request $consumer.full_topic_name, hsh, timeout: 30
    end
    start_time = Time.now
    values     = futures.map { |future| future.value }
    secs       = Time.now - start_time

    expect(futures.map { |x| x.state }).to eq [:fulfilled, :fulfilled, :fulfilled]
    expect(values).to eq [1, 2, 3]
    expect(secs).to be < 2.0
  end

end

describe 'request and response with a custom prefix' do

  before(:context) do
    $consumer        = AdderConsumer
    $previous_prefix = Tiki::Torch.config.topic_prefix
    puts "config.topic_prefix : #{Tiki::Torch.config.topic_prefix}"
    Tiki::Torch.configure { |config| config.topic_prefix = 'custom-' }
    puts "config.topic_prefix : #{Tiki::Torch.config.topic_prefix}"
  end

  before(:each) do
    $lines = TestingHelpers::LogLines.new
    TestingHelpers.setup_vars
    TestingHelpers.setup_torch
  end

  after(:each) do
    Tiki::Torch.configure { |config| config.topic_prefix = $previous_prefix }
    TestingHelpers.take_down_torch
  end

  after(:context) do
    TestingHelpers.take_down_vars
  end

  it 'should be able to successfully make a call' do
    hsh    = { numbers: [1, 2, 3], sleep_time: 0 }
    future = Tiki::Torch.request $consumer.full_topic_name, hsh, timeout: 15

    expect(future).to be_a Concurrent::Future
    expect([:pending, :processing]).to include(future.state)
    expect(future.value(0)).to be_nil

    $lines.wait_for_size 1

    expect(future.value).to eq 6
    expect(future.state).to eq :fulfilled
  end
end
