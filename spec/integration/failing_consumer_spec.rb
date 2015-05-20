describe 'simple consumers', integration: true do
  let(:consumer) { FailingConsumer }
  before(:each) { clear_consumer consumer }

  it 'receives multiple messages' do
    Tiki::Torch.publish consumer.topic, 'failure'
    wait_for 1

    expect($messages.payloads).to eq %w{ failure failure failure }
    expect($messages.attempts).to eq [1, 2, 3]
    expect($messages.message_ids.uniq.size).to eq 1
    expect($messages.consumer_count(consumer.name)).to eq 3
    expect($messages.thread_ids.uniq.size).to eq $messages.size
  end
end
