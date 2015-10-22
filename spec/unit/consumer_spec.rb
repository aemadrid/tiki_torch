module Tiki
  module Torch
    describe Consumer do
      let(:event) { instance_double 'Tiki::Torch::Event', to_s: '#<T:T:Event short_id="abc123", body=42, payload="String">' }
      let(:broker) { instance_double 'Tiki::Torch::ConsumerBroker' }
      let(:klass){ SimpleConsumer }
      subject { klass.new event, broker }
      context 'basic' do
        it('to_s') { expect(subject.to_s).to eq '#<SimpleConsumer event=#<T:T:Event short_id="abc123", body=42, payload="String">>' }
      end
    end
  end
end
