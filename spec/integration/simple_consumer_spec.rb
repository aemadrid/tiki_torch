describe SimpleConsumer, integration: true, polling: true do
  let(:config) { described_class.config }
  context 'queue' do
    let(:queue) { Tiki::Torch.client.queue described_class.queue_name }
    context 'attributes' do
      let!(:attrs) { queue.attributes }
      context 'computed' do
        it('visible_count     ') { expect(attrs.visible_count).to eq 0 }
        it('invisible_count   ') { expect(attrs.invisible_count).to eq 0 }
        it('visibility_timeout') { expect(attrs.visibility_timeout).to eq config.visibility_timeout }
        it('policy            ') { expect(attrs.policy).to be_nil }
        it('max_size          ') { expect(attrs.max_size).to eq config.max_size }
        it('retention_period  ') { expect(attrs.retention_period).to eq config.retention_period }
        it('arn               ') { expect(attrs.arn).to match /^arn\:/ }
        it('delayed_count     ') { expect(attrs.delayed_count).to eq 0 }
        it('default_delay     ') { expect(attrs.default_delay).to eq 0 }
        it('receive_delay     ') { expect(attrs.receive_delay).to eq 0 }
        it('redrive_policy    ') { expect(attrs.redrive_policy).to be_nil }
        context 'on sqs', on_real_sqs: true do
          it('created_at        ') { expect(attrs.created_at).to be_a Time }
          it('updated_at        ') { expect(attrs.updated_at).to be_a Time }
        end
      end
      context 'computed - hash' do
        it('visible_count     ') { expect(attrs[:visible_count]).to eq 0 }
        it('invisible_count   ') { expect(attrs[:invisible_count]).to eq 0 }
        it('visibility_timeout') { expect(attrs[:visibility_timeout]).to eq config.visibility_timeout }
        it('policy            ') { expect(attrs[:policy]).to be_nil }
        it('max_size          ') { expect(attrs[:max_size]).to eq config.max_size }
        it('retention_period  ') { expect(attrs[:retention_period]).to eq config.retention_period }
        it('arn               ') { expect(attrs[:arn]).to match /^arn\:/ }
        it('delayed_count     ') { expect(attrs[:delayed_count]).to eq 0 }
        it('default_delay     ') { expect(attrs[:default_delay]).to eq 0 }
        it('receive_delay     ') { expect(attrs[:receive_delay]).to eq 0 }
        it('redrive_policy    ') { expect(attrs[:redrive_policy]).to be_nil }
        context 'on sqs', on_real_sqs: true do
          it('created_at        ') { expect(attrs[:created_at]).to be_a Time }
          it('updated_at        ') { expect(attrs[:updated_at]).to be_a Time }
        end
      end
      context 'native' do
        it('ApproximateNumberOfMessages          ') { expect(attrs['ApproximateNumberOfMessages']).to eq '0' }
        it('ApproximateNumberOfMessagesNotVisible') { expect(attrs['ApproximateNumberOfMessagesNotVisible']).to eq '0' }
        it('VisibilityTimeout                    ') { expect(attrs['VisibilityTimeout']).to eq config.visibility_timeout.to_s }
        it('Policy                               ') { expect(attrs['Policy']).to be_nil }
        it('MaximumMessageSize                   ') { expect(attrs['MaximumMessageSize']).to eq config.max_size.to_s }
        it('MessageRetentionPeriod               ') { expect(attrs['MessageRetentionPeriod']).to eq config.retention_period.to_s }
        it('QueueArn                             ') { expect(attrs['QueueArn']).to match /^arn\:/ }
        it('DelaySeconds                         ') { expect(attrs['DelaySeconds']).to eq '0' }
        it('ReceiveMessageWaitTimeSeconds        ') { expect(attrs['ReceiveMessageWaitTimeSeconds']).to eq '0' }
        it('RedrivePolicy                        ') { expect(attrs['RedrivePolicy']).to be_nil }
        context 'on sqs', on_real_sqs: true do
          it('ApproximateNumberOfMessagesDelayed   ') { expect(attrs['ApproximateNumberOfMessagesDelayed']).to eq '0' }
          it('CreatedTimestamp                     ') { expect(attrs['CreatedTimestamp']).to match /^\d+$/ }
          it('LastModifiedTimestamp                ') { expect(attrs['LastModifiedTimestamp']).to match /^\d+$/ }
        end
      end
    end
  end
  context 'publishing', focus: true do
    let(:publisher) { Tiki::Torch.publisher }
    it 'processes callbacks on publishing' do
      publisher.add_callback('cb1') {|_, _, _| $lines << 'cb1' }
      publisher.add_callback('cb2') {|_, _, _| $lines << 'cb2' }

      2.times {|nr| consumer.publish 's%02i' % nr }

      $lines.wait_for_size 6, 5

      expect($lines.size).to eq 6
      expect($lines.sorted).to eq %w{ cb1 cb1 cb2 cb2 s00 s01 }

      publisher.callbacks.clear
    end
  end
  context 'processing' do
    context 'multiple' do
      let(:expected) { qty.times.map { |x| 's%02i' % x } }
      shared_examples 'multiple send and receive' do
        it 'properly' do
          qty.times { |nr| consumer.publish 's%02i' % nr }

          $lines.wait_for_size qty, qty / 4.0 * 3

          expect($lines.size).to eq qty
          expect($lines.sorted).to eq expected
        end
      end
      context 'send/receive #1' do
        let(:qty) { 4 }
        it_behaves_like 'multiple send and receive'
      end
      context 'send/receive #2' do
        let(:qty) { 14 }
        it_behaves_like 'multiple send and receive'
      end
      context 'send/receive #3' do
        let(:qty) { 54 }
        it_behaves_like 'multiple send and receive'
      end
    end
  end
end
