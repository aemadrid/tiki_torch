module Tiki
  module Torch
    describe Event do
      let(:body) { "yaml|---\n:payload: hello!\n:properties: {}\n" }
      let(:message) { instance_double 'Tiki::Torch::AwsMessage', short_id: 'abc123', body: body }
      subject { described_class.new message }
      context 'basic' do
        it('to_s') { expect(subject.to_s).to eq '#<T:T:Event short_id="abc123", body=42, payload="String">' }
      end
    end
  end
end
