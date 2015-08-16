describe 'multiple consumers', integration: true do
  let(:consumers) { [MultipleFirstConsumer, MultipleSecondConsumer] }
  let(:msq_qty){ 4 }

  it 'receives multiple messages' do
    msq_qty.times { |nr| Tiki::Torch.publish consumers.first.topic, "m#{nr + 1}" }
    sleep 0.5

    expect($messages.payloads.sort).to eq %w{ m1 m1 m2 m2 m3 m3 m4 m4 }
    expect($messages.thread_ids.uniq.size).to eq $messages.size
    expect($messages.consumer_count(consumers.first.name)).to eq msq_qty
    expect($messages.consumer_count(consumers.last.name)).to eq msq_qty
  end
end
