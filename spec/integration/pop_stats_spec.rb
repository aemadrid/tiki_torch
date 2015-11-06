describe PopStatsConsumer, integration: true, polling: true do
  let(:nr){  Tiki::Torch.config.event_pool_size }
  it 'registers numbers each time it pops', focus: true do
    consumer.publish sleep_time: 1
    $lines.wait_for_size 4

    expect($lines.all).to eq %W{ r:#{nr}|f:0|t:0.5 r:#{nr}|f:1|t:0.5 success r:#{nr}|f:0|t:0.5 }
  end
end