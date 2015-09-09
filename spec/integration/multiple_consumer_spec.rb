describe 'multiple consumers', integration: true do
  before(:context)  { $consumers =  [MultipleFirstConsumer, MultipleSecondConsumer]  }

  it 'receives multiple messages' do
    3.times { |nr| Tiki::Torch.publish $consumers.first.topic, nr + 1 }
    $lines.wait_for_size 6

    expect($lines.all.sort).to eq %w{ c1:1 c1:2 c1:3 c2:1 c2:2 c2:3 }
  end
end
