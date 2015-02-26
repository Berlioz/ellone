class HintEngine
  def initialize(options)
    @options = options
    @board = Board.new
    @hand = Hand.new(2, options[:red_hand])
  end

  def print_game_state
    puts @board
    puts @hand.to_s(@board)
  end

  def run
    0.upto(8).each do |turn|
      # determine active color: blue takes turn 0 normally, red takes if switch is on
      color = ((@options[:switch] ? turn + 1 : turn) % 2) + 1
      human_color = 1
      if color == human_color
        enemy_turn(color)
      else
        hint_turn(color)
      end
    end
  end

  def display_hint_data(color, cards)
    possible_moves = cards.product(@board.open_spaces) #[card, [x, y]]
    ratings = {}

    possible_moves.each do |move|
      card, coords = move
      x, y = coords
      future = @board.next_state(card, x, y)
      score = future.score(color)
      ratings[move] = score
    end
    top_score = ratings.values.max
    winners = ratings.select{|_, score| score == top_score}

    puts "Lookahead analysis:".colorize(:green)
    puts " (evaluated #{possible_moves.count} moves; #{winners.count} winners with score #{top_score}"
    if winners.count == possible_moves.count
      puts "No captures found."
    else
      winners.each do |move, score|
        x, y = move.last
        puts " - #{@hand.name_of_card(move.first)} to (#{x + 1}, #{y + 1})"
      end
      top_score -= 1
      while top_score > @board.score
        runner_ups = ratings.select{|_, score| score == top_score}
        if runner_ups.count > 0
          puts "Runner-ups with score #{top_score}:"
          runner_ups.each do |move, score|
            x, y = move.last
            puts " - #{@hand.name_of_card(move.first)} to (#{x + 1}, #{y + 1})"
          end
        end
        top_score -= 1
      end
    end
  end

  def hint_turn(color)
    print_game_state unless @ongoing_game
    display_hint_data(color, @hand.cards)

    move = nil
    while move.nil?
      move = get_player_input(@hand)
    end
    card, x, y = move

    @board.make_move(card, x - 1, y - 1)
    @ongoing_game = true
    @hand.remove_card(card)

    system "clear"
    print_game_state
  end

  def enemy_turn(color)
    print_game_state unless @ongoing_game
    move = nil
    while move.nil?
      move = get_free_input
    end
    card, x, y = move
    card.color = color

    @board.make_move(card, x - 1, y - 1)
    @ongoing_game = true

    system "clear"
    print_game_state
  end

  def get_player_input(hand)
    puts "Input: card_substring x y (ex. red_giant 2 3)\n"
    input = $stdin.gets.gsub(',' , '').rstrip
    key, x, y = input.split
    if key == "debug"
      binding.pry
      nil
    end
    key = "" if key.nil?
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

  def get_free_input
    puts "Input: any_card x y (ex. red_giant 2 3)\n"
    input = $stdin.gets.gsub(',' , '').rstrip
    key, x, y = input.split
    if key == "debug"
      binding.pry
      nil
    end
    key = "" if key.nil?
    choice = key.gsub("_", " ")
    unless key && x && y
      puts "Malformed expression...\n"
      return nil
    end

    c = CardList.new
    names = c.all_card_names
    card_name = names.detect{|n| n.downcase == choice}
    if card_name.nil?
      substring_matches = names.select{|n| n.downcase.include?(choice)}
      if substring_matches.empty?
        puts "That doesn't match any known cards...\n".colorize(:red)
        return nil
      elsif substring_matches.length > 1
        puts "#{choice} substring is ambiguous; options are #{substring_matches}"
        return nil
      else
        card_name = substring_matches.first
      end
    end
    card = c.card_with_name(card_name)

    unless @board.open_spaces.include?([x.to_i - 1, y.to_i - 1]) && card
      puts "Illegal move...\n"
      return nil
    end
    [card, x.to_i, y.to_i]
  end

end