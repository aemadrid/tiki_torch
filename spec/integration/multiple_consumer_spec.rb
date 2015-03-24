describe 'simple consumers', integration: true do
  let(:consumer) { SimpleConsumer }

  it 'receives multiple messages' do
    (1..4).each { |nr| Tiki::Torch.publish consumer.topic, "a#{nr}" }
    sleep 1

    # Get all messages
    expect($messages.payloads).to eq %w{ a1 a2 a3 a4 }
    # All different threads
    expect($messages.thread_ids.uniq.size).to eq 4
  end
end
