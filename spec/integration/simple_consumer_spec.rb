describe SimpleConsumer do
  let(:config) { described_class.config }
  context 'queue', integration: true do
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
  context 'processing', integration: true do
    context 'after max time' do
      let(:max_wait) { 0.5 }
      let!(:start_time) { Time.now }
      it 'pops regardless of writes' do
        consumer.config.events_sleep_times[:max_wait] = max_wait
        consumer.instance_variable_set '@polled_at', Time.now
        expect(consumer).to receive(:pop_results).at_least(:once)
        sleep max_wait + 1
      end
    end
    context 'multiple' do
      let(:extra) { 3 }
      let(:total) { qty + extra }
      let(:expected) { total.times.map { |x| 's%02i' % x } }
      let(:sleep_time) { ON_REAL_SQS ? 5 : 3 }
      shared_examples 'multiple send and receive' do
        before(:each) {
          @old_wait = described_class.events_sleep_times[:max_wait]
          described_class.events_sleep_times[:max_wait] = 0.5
        }
        it 'properly' do
          qty.times { |nr| consumer.publish 's%02i' % nr }

          $lines.wait_for_size qty, qty
          sleep sleep_time

          extra.times { |nr| consumer.publish 's%02i' % (qty + nr) }
          $lines.wait_for_size total, extra * 2

          expect($lines.size).to eq total
          expect($lines.sorted).to eq expected

          described_class.events_sleep_times[:max_wait] = 0.5
        end
        after(:each){ described_class.events_sleep_times[:max_wait] = @old_wait }
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
        let(:qty) { 55 }
        it_behaves_like 'multiple send and receive'
      end
    end
  end
end
