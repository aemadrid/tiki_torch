module Tiki
  module Torch
    describe AwsQueue, integration: true do
      let(:text) { 'Hello!' }
      context 'single' do
        context 'text message' do
          let(:params) { [text] }
          it 'sends and receives' do
            sent = queue.send_message *params
            expect(sent).to be_a Seahorse::Client::Response

            received = queue.receive_messages max_number_of_messages: 1
            expect(received).to be_a Array
            expect(received.size).to eq 1

            msg = received.first
            expect(msg).to be_a Tiki::Torch::AwsMessage
            expect(msg.message_id).to eq sent.message_id
            expect(msg.body).to eq text
            expect(msg.queue_name).to eq queue_name
          end
        end
        context 'hash message' do
          let(:params) { [{ message_body: text }] }
          it 'sends and receives' do
            sent = queue.send_message *params
            expect(sent).to be_a Seahorse::Client::Response

            received = queue.receive_messages max_number_of_messages: 1
            expect(received).to be_a Array
            expect(received.size).to eq 1

            msg = received.first
            expect(msg).to be_a Tiki::Torch::AwsMessage
            expect(msg.message_id).to eq sent.message_id
            expect(msg.body).to eq text
            expect(msg.queue_name).to eq queue_name
          end
        end
      end
      context 'multiple' do
        context 'text message' do
          let(:params) { [text, text] }
          it 'sends and receives' do
            sent = queue.send_messages params
            expect(sent).to be_a Seahorse::Client::Response
            expect(sent.data.successful.size).to eq 2
            expect(sent.data.failed.size).to eq 0
            sent_mids = sent.data.successful.map { |x| x.message_id }.sort

            received = queue.receive_messages max_number_of_messages: 2
            expect(received).to be_a Array
            expect(received.size).to eq 2
            expect([Tiki::Torch::AwsMessage]).to eq received.map { |x| x.class }.sort.uniq
            expect([text]).to eq received.map { |x| x.body }.sort.uniq
            expect(sent_mids).to eq received.map { |x| x.message_id }.sort
          end
        end
        context 'hash message' do
          let(:params) { { entries: [{ id: '0', message_body: text }, { id: '1', message_body: text }] } }
          it 'sends and receives' do
            sent = queue.send_messages params
            expect(sent).to be_a Seahorse::Client::Response
            expect(sent.data.successful.size).to eq 2
            expect(sent.data.failed.size).to eq 0
            sent_mids = sent.data.successful.map { |x| x.message_id }.sort

            received = queue.receive_messages max_number_of_messages: 2
            expect(received).to be_a Array
            expect(received.size).to eq 2
            expect([Tiki::Torch::AwsMessage]).to eq received.map { |x| x.class }.sort.uniq
            expect([text]).to eq received.map { |x| x.body }.sort.uniq
            expect(sent_mids).to eq received.map { |x| x.message_id }.sort
          end
        end
      end
    end
  end
end

__END__
sent (Seahorse::Client::Response)
  #<struct Aws::SQS::Types::SendMessageResult
    md5_of_message_body="952d2c56d0485958336747bcdd98590d",
    md5_of_message_attributes=nil,
    message_id="632cd219-8f9e-47fe-8751-78b9094e626b">
received (Array) [
  #<Tiki::Torch::Message:0x007fd3dea61530
    @client=#<Aws::SQS::Client>,
    @data=#<struct Aws::SQS::Types::Message
      message_id="632cd219-8f9e-47fe-8751-78b9094e626b",
      receipt_handle="525a04a2a88b88caae2b7e9bf53f921f",
      md5_of_body="952d2c56d0485958336747bcdd98590d",
      body="Hello!",
      attributes={},
      md5_of_message_attributes=nil,
      message_attributes={}>,
    @queue_url="http://0.0.0.0:4568/fake-sqs-queue",
    @queue_name="fake-sqs-queue">]
