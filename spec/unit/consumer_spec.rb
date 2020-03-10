# frozen_string_literal: true

module Tiki
  module Torch
    describe Consumer, :fast do
      let(:event) { instance_double 'Tiki::Torch::Consumer::Event', to_s: '#<T:T:C:Event short_id="abc123", body=42, payload="String">' }
      let(:broker) { instance_double 'Tiki::Torch::ConsumerBroker' }
      let(:klass) { SimpleConsumer }
      context 'class' do
        subject { klass }
        context 'config' do
          it('topic')              { expect(subject.topic).to eq 'simple' }
          it('prefix')             { expect(subject.prefix).to eq config.prefix }
          it('channel')            { expect(subject.channel).to eq config.channel }

          it('default_delay')      { expect(subject.default_delay).to eq config.default_delay }
          it('max_size')           { expect(subject.max_size).to eq config.max_size }
          it('retention_period')   { expect(subject.retention_period).to eq config.retention_period }
          it('policy')             { expect(subject.policy).to eq config.policy }
          it('receive_delay')      { expect(subject.receive_delay).to eq config.receive_delay }
          it('visibility_timeout') { expect(subject.visibility_timeout).to eq config.visibility_timeout }

          it('use_dlq')            { expect(subject.use_dlq).to eq config.use_dlq }
          it('dlq_postfix')        { expect(subject.dlq_postfix).to eq config.dlq_postfix }
          it('max_attempts')       { expect(subject.max_attempts).to eq config.max_attempts }

          it('event_pool_size')    { expect(subject.event_pool_size).to eq config.event_pool_size }
          it('transcoder_code')    { expect(subject.transcoder_code).to eq config.transcoder_code }
          it('events_sleep_times') { expect(subject.events_sleep_times).to eq config.events_sleep_times }
        end
      end
      context 'instance' do
        subject { klass.new event, broker }
        context 'basic' do
          it('to_s') { expect(subject.to_s).to eq '#<SimpleConsumer event=#<T:T:C:Event short_id="abc123", body=42, payload="String">>' }
        end
      end
    end
  end
end
