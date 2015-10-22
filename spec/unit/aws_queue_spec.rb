# module Tiki
#   module Torch
#     describe AwsQueue do
#       let(:queue_name) { 'fake-sqs-queue' }
#       subject { Tiki::Torch.client.queue queue_name }
#       context 'basic' do
#         it('to_s') { expect(subject.to_s).to eq '#<T:T:AwsQueue name="fake-sqs-queue">' }
#       end
#       context 'attributes' do
#         let(:attrs) { queue.attributes }
#         it('attrs             ') { expect(attrs).to be_a AwsQueueAttributes }
#         it('visible_count     ') { expect(attrs.visible_count).to eq 0 }
#         it('invisible_count   ') { expect(attrs.visible_count).to eq 0 }
#       end
#     end
#   end
# end
