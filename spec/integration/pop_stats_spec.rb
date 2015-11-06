describe PopStatsConsumer, integration: true, polling: true do
  let(:nr) { consumer.event_pool_size }
  let(:qty) { 3 }
  it 'registers numbers each time it pops', focus: true do
    consumer.publish sleep_time: 1
    $lines.wait_for_size qty, 10

    expect($lines.all).to eq [consumer.tag] * qty
  end
end