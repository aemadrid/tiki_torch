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
    context 'after max time', focus: true do
      let(:max_wait) { 0.5 }
      let!(:start_time) { Time.now }
      it 'pops regardless of writes' do
        consumer.config.events_sleep_times[:max_wait] = max_wait
        consumer.instance_variable_set '@polled_at', Time.now
        expect(consumer).to receive(:pop_results)
        sleep max_wait + 0.1
      end
    end
    context 'multiple' do
      let(:extra) { 3 }
      let(:total) { qty + extra }
      let(:expected) { total.times.map { |x| 's%02i' % x } }
      shared_examples 'multiple send and receive' do
        it 'properly' do
          qty.times { |nr| consumer.publish 's%02i' % nr }

          $lines.wait_for_size qty, qty
          sleep 3

          extra.times { |nr| consumer.publish 's%02i' % (qty + nr) }
          $lines.wait_for_size total, extra * 2

          expect($lines.size).to eq total
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
        let(:qty) { 55 }
        it_behaves_like 'multiple send and receive'
      end
    end
  end
  context 'monitoring' do
    let(:empty) { { published: 0, pop: 0, received: 0, success: 0, failure: 0 } }
    let(:early) { { published: 3, pop: 1, received: 3, success: 2, failure: 1 } }
    let(:earlier) { { published: 5, pop: 3, received: 5, success: 2, failure: 3 } }
    let(:full) { { published: 8, pop: 4, received: 8, success: 4, failure: 4 } }
    let(:times) { [5, 30] }
    it 'reports numbers on time' do
      clear_redis

      base = consumer.stats times
      expect(base).to be_a Hash
      expect(base.keys.sort).to eq times
      expect(base[5]).to eq empty
      expect(base[30]).to eq empty

      early.each { |k, v| consumer.store_stat k, v, 4.minutes.ago }
      earlier.each { |k, v| consumer.store_stat k, v, 24.minutes.ago }

      final = consumer.stats times
      expect(final).to be_a Hash
      expect(final.keys.sort).to eq times
      expect(final[5]).to eq early
      expect(final[30]).to eq full
    end
  end
end
