describe 'request and response', integration: true do
  let(:consumer) { AdderConsumer }

  it 'requesting returns a future and in time we get a value' do
    hsh    = { numbers: [1, 2, 3], sleep_time: 5 }
    future = Tiki::Torch.request consumer.topic, hsh, timeout: 15

    expect(future).to be_a Concurrent::Future
    expect(future.state).to eq :processing
    expect(future.value(0)).to be_nil

    $lines.wait_for_size 1

    expect(future.value).to eq 6
    expect(future.state).to eq :fulfilled
  end

  it 'requesting returns a future that times out' do
    hsh    = { numbers: [1, 2, 3], sleep_time: 5 }
    future = Tiki::Torch.request consumer.topic, hsh, timeout: 2

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
    expect(reason.topic_name).to eq consumer.topic
    expect(reason.payload).to eq hsh
    expect(reason.properties).to be_a Hash
  end

end
