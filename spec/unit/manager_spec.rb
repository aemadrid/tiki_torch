module Tiki
  module Torch
    describe Manager do
      let(:client) { instance_double 'Tiki::Torch::AwsClient', to_s: '#<T:T:AwsClient>' }
      subject { described_class.new client, Torch.config }
      context 'basic' do
        let(:exp_str) { %{#<T:T:Manager brokers=#{subject.brokers.size} config=#<T:T:Config access_key_id="#{TEST_ACCESS_KEY_ID}" region="#{TEST_REGION}"> client=#<T:T:AwsClient>>} }
        it('to_s') { expect(subject.to_s).to eq exp_str }
      end
    end
  end
end
