describe 'multiple consumers', integration: true do
  let(:consumers) { [MultipleFirstConsumer, MultipleSecondConsumer] }

  it 'receives multiple messages' do
    max = 4
    max.times { |nr| Tiki::Torch.publish consumers.first.topic, "m#{nr + 1}" }
    sleep 1

    expect($messages.payloads.sort).to eq %w{ m1 m1 m2 m2 m3 m3 m4 m4 }
    expect($messages.thread_ids.uniq.size).to eq $messages.size
    expect($messages.consumer_count(consumers.first.name)).to eq max
    expect($messages.consumer_count(consumers.last.name)).to eq max
  end
end
