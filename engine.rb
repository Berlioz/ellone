class Engine
  def initialize(options)
    @options = options
    @board = Board.new
    if options[:blue_hand] && options[:red_hand]
      @blue_hand = Hand.new(1, options[:blue_hand])
      @red_hand = Hand.new(2, options[:red_hand])
    else
      @blue_hand = Hand.from_random(1, options[:power_level])
      @red_hand = Hand.from_random(2, options[:power_level])
    end
    @depth = options[:depth]
  end

  def print_game_state
    puts @board
    puts @blue_hand.to_s(@board)
    puts @red_hand.to_s(@board)
  end

  def run
    if @options[:mode] == :test
      run_test_game
    elsif @options[:mode] == :pvp
      run_pvp_game
    elsif @options[:mode] == :manual
      run_manual_game
    end
  end

  def run_test_game
    0.upto(8).each do |turn|
      color = (turn % 2) + 1
      ai_turn(color)
    end
    score_for_blue = @board.score + @blue_hand.cards.length - @red_hand.cards.length
    puts "Final score is: " + "#{score_for_blue < 0 ? '' : '+'}#{score_for_blue}".colorize(score_for_blue >= 0 ? :green : :red)
  end

  def run_pvp_game
    0.upto(8).each do |turn|
      # determine active color: blue takes turn 0 normally, red takes if switch is on
      color = ((@options[:switch] ? turn + 1 : turn) % 2) + 1
      human_color = 1
      if color == human_color
        human_turn(color)
      elsif turn == 0 && @options[:first_manual]
        human_turn(color)
      else
        ai_turn(color)
      end
    end
    score_for_blue = @board.score + @blue_hand.cards.length - @red_hand.cards.length
    puts "Final score is: " + "#{score_for_blue < 0 ? '' : '+'}#{score_for_blue}".colorize(score_for_blue >= 0 ? :green : :red)
  end

  def run_manual_game
    0.upto(8).each do |turn|
      color = (turn % 2) + 1
      human_turn(color)
    end
    score_for_blue = @board.score + @blue_hand.cards.length - @red_hand.cards.length
    puts "Final score is: " + "#{score_for_blue < 0 ? '' : '+'}#{score_for_blue}".colorize(score_for_blue >= 0 ? :green : :red)
  end

  private

  def ai_turn(to_play)
    puts "AI is thinking...(difficulty #{@options[:depth]})"
    n = NegamaxAgent.new(@board, get_active_hand(to_play).cards, get_passive_hand(to_play).cards, @options[:depth])
    n_card, n_x, n_y, n_s = n.invoke
    system "clear"

    @board.make_move(n_card, n_x, n_y)
    cardname = get_active_hand(to_play).name_of_card(n_card)
    get_active_hand(to_play).remove_card(n_card)
    @ongoing_game = true
    print_game_state
    puts "AI played #{cardname} to #{n_x}, #{n_y}... #{@board.open_spaces.count} spaces left."
    puts "DEBUG: AI believes it can achieve a score of #{n_s} with optimal play"
  end

  def human_turn(to_play)
    print_game_state unless @ongoing_game
    hand = get_active_hand(to_play)

    player_move = nil
    while player_move.nil?
      player_move = get_input(hand)
    end
    card, x, y = player_move

    @board.make_move(card, x - 1, y - 1)
    hand.remove_card(card)
    @ongoing_game = true

    system "clear"
    print_game_state
    puts "#{@board.open_spaces.count} spaces left. Enter to continue..."
    _ = $stdin.gets
  end

  def get_active_hand(active_player)
    active_player == 1 ? @blue_hand : @red_hand
  end

  def get_passive_hand(active_player)
    active_player == 2 ? @blue_hand : @red_hand
  end

  def get_input(hand)
    puts "Input: card_substring x y (ex. red_giant 2 3)\n"
    input = $stdin.gets.gsub(',' , '').rstrip
    key, x, y = input.split
    if key == "debug"
      binding.pry
      nil
    end
    key = key.gsub("_", " ")
    unless key && x && y
      puts "Malformed expression...\n"
      return nil
    end
    card_name = hand.names.detect{|name| name.downcase.include?(key.downcase)}
    card = hand.card_with_name(card_name)
    unless @board.open_spaces.include?([x.to_i - 1, y.to_i - 1]) && card
      puts "Illegal move...\n"
      return nil
    end
    [card, x.to_i, y.to_i]
  end
end