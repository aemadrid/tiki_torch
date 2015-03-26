describe 'simple consumers', integration: true do
  let(:consumers) { [MultipleFirstConsumer, MultipleSecondConsumer] }

  it 'receives multiple messages' do
    max = 4
    max.times { |nr| Tiki::Torch.publish consumers.first.topic, "a#{nr + 1}" }
    sleep 1

    # Get all messages
    expect($messages.payloads.sort).to eq %w{ a1 a1 a2 a2 a3 a3 a4 a4 }
    # All different threads
    expect($messages.thread_ids.uniq.size).to eq $messages.size
    # For one consumer
    expect($messages.consumer_count(consumers.first.name)).to eq max
    expect($messages.consumer_count(consumers.last.name)).to eq max
  end
end
