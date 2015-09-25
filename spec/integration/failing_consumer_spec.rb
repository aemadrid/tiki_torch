describe 'failing consumers', integration: true do
  before(:context)  { $consumer = FailingConsumer }

  it 'report failures and sends to DLQ in the end' do
    expect_nsq_topic_count $consumer.full_dlq_topic_name, 0
    Tiki::Torch.publish $consumer.topic, 'failure'
    $lines.wait_for_size 3

    expect($lines.all).to eq %w{ failed:1:requeued failed:2:requeued failed:3:dead }
    expect_nsq_topic_count $consumer.full_dlq_topic_name, 1
  end
end
