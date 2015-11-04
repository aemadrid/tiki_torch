class PopStatsConsumer < Tiki::Torch::Consumer

  include TestingHelpers::Consumer

  consumes 'pop_stats'

  def process
    $lines << 'success'
  end

  def self.pop_results(req_size, found_size, timeout)
    super
    $lines << "r:#{req_size}|f:#{found_size}|t:#{timeout}"
  end

end
