RSpec.shared_examples "a yaml message with prefix" do
  it "publishes" do
    publish_message
    result = TestQueue.pop
    matches = [
      /\Ayaml|/,
      /:payload:\n  :foo:\n    :bar: buzz/,
      /:properties:/,
      /:message_id:/,
      /:published_at:/,
      /:color: yellow/,
      /:purpose: shenanigans/
    ]
    matches.each{ |m| expect(result).to match(m) }
  end
end

RSpec.shared_examples "a json message with prefix" do
  it "publishes" do
    publish_message
    result = TestQueue.pop
    matches = [
      /\Ajson|/,
      /\"payload\":{\"foo\":{\"bar\":\"buzz\"}}/,
      /\"properties\":{/,
      /\"message_id\":/,
      /\"published_at\":/,
      /\"color\":\"yellow\"/,
      /\"purpose\":\"shenanigans\"/
    ]
    matches.each{ |m| expect(result).to match(m) }
  end
end

RSpec.shared_examples "a yaml message with attributes" do
  it "publishes" do
    publish_message
    result = TestQueue.pop
    expect(result.keys).to include(:message_body, :message_attributes)
    expect(result[:message_body]).to match(/---\n:foo:\n  :bar: buzz/)
    expect(result[:message_attributes].keys).to include("Content-Type", "messageId", "publishedAt", "color", "purpose")
    expect(result[:message_attributes]["Content-Type"][:string_value]).to eq("yaml")
  end
end

RSpec.shared_examples "a json message with attributes" do
  it "publish" do
    publish_message
    result = TestQueue.pop
    expect(result.keys).to include(:message_body, :message_attributes)
    expect(result[:message_body]).to match(/{\"foo\":{\"bar\":\"buzz\"}}/)
    expect(result[:message_attributes].keys).to include("Content-Type", "messageId", "publishedAt", "color", "purpose")
    expect(result[:message_attributes]["Content-Type"][:string_value]).to eq("json")
  end
end
