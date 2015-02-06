class Benchmark
  def initialize(depth)
    @board = Board.new
    @blue_hand = Hand.new(1)
    @red_hand = Hand.new(2)
    @depth = depth
  end

  def run
    0.upto(8).each do |turn|
      color = (turn % 2) + 1
      benchmark_turn(color, turn)
    end
  end

  def benchmark_turn(color, turn_number)
    start_time = Time.now
    n = NegamaxAgent.new(@board, get_active_hand(color).cards, get_passive_hand(color).cards, @depth, true)
    n_card, n_x, n_y, n_s = n.invoke
    debug_data = n.get_stats
    @board.make_move(n_card, n_x, n_y)
    get_active_hand(color).remove_card(n_card)
    end_time = Time.now

    s = "Move #{turn_number} took #{((end_time - start_time) * 1000).to_i} ms. "
    s += "(#{debug_data[0]} nodes expanded, #{debug_data[1]} leaves expanded, #{debug_data[2]} branches pruned)"
    puts s
  end

  def get_active_hand(active_player)
    active_player == 1 ? @blue_hand : @red_hand
  end

  def get_passive_hand(active_player)
    active_player == 2 ? @blue_hand : @red_hand
  end
end