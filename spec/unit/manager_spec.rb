module Tiki
  module Torch
    describe Manager, :fast do
      let(:client) { instance_double 'Tiki::Torch::AwsClient', to_s: '#<T:T:AwsClient>' }
      subject { described_class.new }
      context 'basic' do
        let(:exp_str) { %{#<T:T:Manager brokers=#{subject.brokers.size}>} }
        it('to_s') { expect(subject.to_s).to eq exp_str }
      end
    end
  end
end
