describe FailingConsumer, integration: true, polling: true do
  let(:queue_name) { consumer.queue_name }
  it 'report failures and sends to DLQ in the end', on_real_sqs: true do
    expect(queue.attributes).to be_a Tiki::Torch::AwsQueueAttributes
    expect(queue[:visible_count]).to eq 0
    expect(queue[:invisible_count]).to eq 0
    expect(queue[:visibility_timeout]).to eq 30

    consumer.publish 'failure'
    $lines.wait_for_size 3, 15

    expect($lines.all).to eq %w{ failed:left_for_dead failed:left_for_dead failed:left_for_dead }
    sleep 5

    expect(queue[:visible_count]).to eq 0
    expect(queue[:invisible_count]).to eq 0
    # @todo: create DLQ and make sure it has the message there
  end
end

__END__
QueueArn: arn:aws:sqs:us-east-1:315174919334:tiki_torch-failing-events
ApproximateNumberOfMessages: '0'
ApproximateNumberOfMessagesNotVisible: '0'
ApproximateNumberOfMessagesDelayed: '0'
CreatedTimestamp: '1445473922'
LastModifiedTimestamp: '1445473922'
VisibilityTimeout: '30'
MaximumMessageSize: '262144'
MessageRetentionPeriod: '345600'
DelaySeconds: '0'
ReceiveMessageWaitTimeSeconds: '0'