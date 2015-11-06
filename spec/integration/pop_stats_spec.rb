describe PopStatsConsumer, integration: true, polling: true, focus: true do
  let(:nr) { consumer.event_pool_size }
  let(:qty) { 2 }
  let!(:start_time) { Time.now }
  it 'registers numbers each time it pops', focus: true do
    consumer.publish sleep_time: 1
    $lines.wait_for_size qty, 10

    expect($lines.all).to eq [consumer.tag] * qty
    expect(consumer.count_since(:pop, start_time)).to eq 2
  end
end