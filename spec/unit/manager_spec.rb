module Tiki
  module Torch
    describe Manager do
      let(:client) { instance_double 'Tiki::Torch::AwsClient', to_s: '#<T:T:AwsClient>' }
      subject { described_class.new client, Torch.config }
      context 'basic' do
        it('to_s') { expect(subject.to_s).to eq '#<T:T:Manager brokers=2 config=#<T:T:Config access_key_id="fake_access_key" region="fake_region"> client=#<T:T:AwsClient>>' }
      end
    end
  end
end
