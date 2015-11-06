describe FailingConsumer, integration: true, polling: true, on_real_sqs: true do

  let(:config) { described_class.config }
  let(:queue_name) { described_class.queue_name }
  let(:dlq_name) { described_class.dead_letter_queue_name }
  context 'queue' do
    let(:queue) { Tiki::Torch.client.queue queue_name }
    it 'attributes' do
      attrs = queue.attributes
      expect(attrs.visible_count).to be_a Integer
      expect(attrs.invisible_count).to be_a Integer
      expect(attrs.visibility_timeout).to eq 3

      policy = JSON.parse attrs.redrive_policy
      expect(policy['deadLetterTargetArn']).to match /#{dlq_name}$/
      expect(policy['maxReceiveCount']).to eq consumer.max_attempts
    end
  end
  context 'dlq' do
    let(:dl_queue) { Tiki::Torch.client.queue dlq_name }
    it 'report failures and sends to DLQ in the end' do
      consumer.publish 'failure'
      $lines.wait_for_size 3, 30

      expect($lines.all.uniq).to eq %w{ failed:left_for_dead }
      sleep consumer.visibility_timeout + 1

      attrs = queue.attributes
      expect(attrs.visible_count).to be_a Integer
      expect(attrs.invisible_count).to be_a Integer

      dlq_attrs = dl_queue.attributes
      expect(dlq_attrs.visible_count).to eq 1
      expect(dlq_attrs.invisible_count).to eq 0
    end
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