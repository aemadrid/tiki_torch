describe 'simple consumers', integration: true do
  let(:consumer) { SimpleConsumer }

  it 'receives multiple messages' do
    max = 4
    max.times { |nr| Tiki::Torch.publish consumer.topic, "a#{nr + 1}" }
    sleep 1

    # Got all messages
    expect($messages.payloads).to eq %w{ a1 a2 a3 a4 }
    # For one consumer
    expect($messages.consumer_count(consumer.name)).to eq max
    # All different threads
    expect($messages.thread_ids.uniq.size).to eq $messages.size
  end
end
