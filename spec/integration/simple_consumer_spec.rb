describe 'simple consumers', integration: true do
  let(:consumer) { SimpleConsumer }
  before(:each) { clear_consumer consumer }

  it 'receives multiple messages' do
    max = 4
    max.times { |nr| Tiki::Torch.publish consumer.topic, "s#{nr + 1}" }
    wait_for 1

    expect($messages.payloads).to eq %w{ s1 s2 s3 s4 }
    expect($messages.consumer_count(consumer.name)).to eq max
    expect($messages.thread_ids.uniq.size).to eq $messages.size
  end
end
