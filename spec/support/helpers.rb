module TestingHelpers
  class Messages

    Message = Struct.new :consumer, :id, :payload, :properties, :thread_id

    attr_reader :all

    def initialize
      @all = ThreadSafe::Array.new
    end

    def size
      all.size
    end

    def add(class_name, event)
      all << Message.new(class_name, event.message_id, event.payload, event.properties, Thread.current.object_id)
    end

    def add_payload(class_name, payload)
      all << Message.new(class_name, nil, payload, nil, Thread.current.object_id)
    end

    def message_ids
      all.map { |x| x.message_id }
    end

    def payloads
      all.map { |x| x.payload }
    end

    def properties
      all.map { |x| x.properties }
    end

    def thread_ids
      all.map { |x| x.thread_id }
    end

    def consumer_count(class_name)
      all.count { |x| x.consumer == class_name }
    end

  end
end

def setup_torch
  Tiki::Torch.configure do |c|
    if (lkd = ENV['NSLOOKUPD_ADDRESS'])
      c.nsqlookupd = lkd
    elsif (nsd = ENV['NSQD_ADDRESS'])
      c.nsqd = nsd
    else
      c.nsqd = 'localhost:4150'
    end
    c.colorized = false
  end
  # Tiki::Torch.logger.level = Logger::DEBUG
  Tiki::Torch.start_polling
end

def take_down_torch
  Tiki::Torch.shutdown
end

