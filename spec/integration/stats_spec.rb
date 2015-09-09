describe 'consumer stats', integration: true do
  let(:consumer) { StatsConsumer }

  it 'counts starts, processed, succeeded and failed runs' do
    3.times { Tiki::Torch.publish consumer.topic, status: 'ok' }
    $lines.wait_for_size 3

    expect(consumer.stats).to be_a Tiki::Torch::Stats
    expect(consumer.stats.to_hash).to eq({ started: 3, processed: 3, succeeded: 3, failed: 0 })
  end
end
