require './board.rb'
require './card_list.rb'
require './negamax_agent.rb'

$switch = false
if ARGV.length == 2
  Random.srand(ARGV.first.to_i)
  $switch = true
elsif ARGV.length == 1
  Random.srand(ARGV.first.to_i)
end

class TestGame
  def initialize(hints = false, difficulty = 8)
    @board = Board.new
    @card_list = CardList.new
    @player_hand = generate_hand(1)
    @ai_hand = generate_hand(2)
    @difficulty = difficulty
    @hints = hints

    if $switch
    	puts "switching hands..."
 		@player_hand.each do |k, v|
 			v.color = 2
 		end
 		@ai_hand.each do |k, v|
 			v.color = 1
 		end
 		temp = @ai_hand
 		@ai_hand = @player_hand
 		@player_hand = temp
    end
  end

  def run
  	0.upto(8).each do |turn|
  	  turn % 2 == ($switch ? 1 : 0) ? player_move(turn) : ai_move(turn)
    end
    puts "Final score is: " + "#{game_score(@board.score) < 0 ? '-' : '+'}#{game_score(@board.score)}".colorize(@board.score >= 0 ? :green : :red) + " (board score #{@board.score})"
  end

  def game_score(score)
    if @player_hand.values.compact.length > 0
      score + 1
    else
      score - 1
    end
  end

  def generate_hand(c)
    rv = {}
    choices = [6,7,8,9,10].map {|rank| @card_list.card_with_rank(rank)}
    justify = choices.map{|c| c.first.length}.max

    choices.each_with_index do |choice, index|
      name, card = choice
      name = sprintf("%d %-#{justify}s", index, name)
      card.color = c
      rv[name] = card
    end
    rv
  end

  def pc(card, row)
    card.nil? ? "       " : card.row(row)
  end

  def display_game
    puts "BOARD STATE:\n"
    puts @board
    puts "PLAYER HAND:\n"
    display_hand
  end

  def display_hand
  	names = @player_hand.keys
    cards = @player_hand.values
    # a normal card is 7 characters across
    interstitial_length = [1, names.map(&:length).max - 6].max
    i = ' ' * interstitial_length
    puts "#{names[0]} #{names[1]} #{names[2]} #{names[3]} #{names[4]}".colorize(:green)
    puts "#{pc(cards[0], 0)}#{i}#{pc(cards[1], 0)}#{i}#{pc(cards[2], 0)}#{i}#{pc(cards[3], 0)}#{i}#{pc(cards[4], 0)}"
    puts "#{pc(cards[0], 1)}#{i}#{pc(cards[1], 1)}#{i}#{pc(cards[2], 1)}#{i}#{pc(cards[3], 1)}#{i}#{pc(cards[4], 1)}"
    puts "#{pc(cards[0], 2)}#{i}#{pc(cards[1], 2)}#{i}#{pc(cards[2], 2)}#{i}#{pc(cards[3], 2)}#{i}#{pc(cards[4], 2)}"
    cards = @ai_hand.values
    puts "AI HAND:"
    puts "#{pc(cards[0], 0)}#{i}#{pc(cards[1], 0)}#{i}#{pc(cards[2], 0)}#{i}#{pc(cards[3], 0)}#{i}#{pc(cards[4], 0)}"
    puts "#{pc(cards[0], 1)}#{i}#{pc(cards[1], 1)}#{i}#{pc(cards[2], 1)}#{i}#{pc(cards[3], 1)}#{i}#{pc(cards[4], 1)}"
    puts "#{pc(cards[0], 2)}#{i}#{pc(cards[1], 2)}#{i}#{pc(cards[2], 2)}#{i}#{pc(cards[3], 2)}#{i}#{pc(cards[4], 2)}"
  end

  # print a player move which results in maximum score shift
  def display_hint(board, current_hand, ai_hand)
    n = NegamaxAgent.new(board, current_hand, ai_hand)
    n_suggested_move = n.invoke
    n_suggested_card = n_suggested_move.first
    n_x = n_suggested_move[1]
    n_y = n_suggested_move[2]
    n_s = n_suggested_move[3]

    puts "HINT: negamax suggested #{@player_hand.key(n_suggested_card).strip[2..-1]} @ #{n_x + 1}, #{n_y + 1} is no worse (#{n_s}) than your best move."
  end

  def determine_ai_move(board, ai_hand, player_hand)
    n = NegamaxAgent.new(board, ai_hand.values.compact, player_hand.values.compact)
    n_suggested_move = n.invoke
    n_suggested_card = n_suggested_move.first
    n_x = n_suggested_move[1]
    n_y = n_suggested_move[2]
    n_s = n_suggested_move[3]
    return {:move => [n_suggested_card, n_x, n_y], :score => n_s}
  end

  # ply 1 only!
  # returns the best score the player can get in response to the move the AI
  # makes which creates future_board. the AI is trying to pick a move which
  # MINIMIZES this value.
  def retard_minimax(future_board, player_hand)
    available_cards = player_hand.values.compact
    available_spaces = future_board.open_spaces
    possible_moves = available_cards.product(available_spaces)
    value_of_best_move = -10

    possible_moves.each do |card, space|
      x, y = space
      value = future_board.next_state(card, x, y).score
      if value > value_of_best_move
        value_of_best_move = value
      end
    end

    return value_of_best_move
  end

  def get_input
    puts "Input: card_letter x y (ex. c 2 3)\n"
    input = $stdin.gets.gsub(',' , '').rstrip
    letter, x, y = input.split
    unless letter && x && y
      puts "Malformed expression...\n"  
      return nil
    end
    key = @player_hand.keys.detect{|k| k[0] == letter.upcase}
    card = @player_hand[key]
    unless @board.open_spaces.include?([x.to_i - 1, y.to_i - 1]) && card
      puts "Illegal move...\n"
      return nil
    end
    [card, x.to_i, y.to_i]
  end

  def player_move(turn)
  	if turn == 0
  	  system "clear"
  	  display_game
  	end
  	display_hint(@board, @player_hand.values.compact, @ai_hand.values.compact) if @hints
    
    player_move = nil
    while player_move.nil?
      player_move = get_input
    end
    card, x, y = player_move

    @board.make_move(card, x - 1, y - 1)
    @player_hand[@player_hand.key(card)] = nil 

    system "clear"
    display_game
    puts "#{@board.open_spaces.count} spaces left. Enter to continue..."
    _ = $stdin.gets
  end

  def ai_move(turn)
    puts "AI is thinking..."
    output = determine_ai_move(@board, @ai_hand, @player_hand)
    move = output[:move]
    score = output[:score]
    system "clear"
    card, x, y = move
    @board.make_move(card, x, y)
    @ai_hand.delete(@ai_hand.key(card))

    display_game
    puts "AI played a card to #{x}, #{y}... #{@board.open_spaces.count} spaces left."
    puts "DEBUG: AI believes the board has a value of #{score}"
  end
end

r = Rules.instance
puts "Do you want to use the default rules? (Plus, Same, Combo, Same Wall). Y/N"
default_rules = $stdin.gets.rstrip.upcase[0] == "Y"
if default_rules  
  r.base = true
  r.plus = true
  r.same = true
  r.combo = true
  r.same_wall = true
else
  r.base = true
  puts "PLUS? Y/N"
  r.plus = $stdin.gets.rstrip.upcase[0] == "Y"
  puts "SAME? Y/N"
  r.same = $stdin.gets.rstrip.upcase[0] == "Y"
  puts "COMBO? Y/N"
  r.combo = $stdin.gets.rstrip.upcase[0] == "Y"
  if r.same
    puts "SAME WALL? Y/N"
    r.same_wall = $stdin.gets.rstrip.upcase[0] == "Y"
  else
    r.same_wall = false
  end
end

puts "Please enter difficulty/lookahead length (2-8 inclusive):"
difficulty = $stdin.gets.rstrip.to_i
difficulty = 2 if difficulty < 2
difficulty = 8 if difficulty > 8
puts "Do you want hints? Y/N"
hints = $stdin.gets.rstrip.upcase[0] == "Y"
t = TestGame.new(hints, difficulty)
t.run