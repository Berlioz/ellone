require 'pry'
require './board.rb'
require './negamax_agent.rb'

class TestGame
  def initialize
    @board = Board.new
    @player_hand = generate_hand(1)
    @ai_hand = generate_hand(2)
  end

  def run
  	0.upto(8).each do |turn|
  	  turn % 2 == 0 ? player_move(turn) : ai_move(turn)
    end
    puts "Final score is: " + "#{@board.score}".colorize(@board.score >= 0 ? :green : :red)
  end

  def generate_hand(c)
    cards = [Card.init_random(c), Card.init_random(c), Card.init_random(c), Card.init_random(c), Card.init_random(c)]
    {"ALPHA  " => cards[0], "BRAVO  " => cards[1], "CHARLIE" => cards[2], "DELTA  " => cards[3], "ECHO   " => cards[4]}
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
    puts "#{names[0]} #{names[1]} #{names[2]} #{names[3]} #{names[4]}".colorize(:green)
    puts "#{pc(cards[0], 0)} #{pc(cards[1], 0)} #{pc(cards[2], 0)} #{pc(cards[3], 0)} #{pc(cards[4], 0)}"
    puts "#{pc(cards[0], 1)} #{pc(cards[1], 1)} #{pc(cards[2], 1)} #{pc(cards[3], 1)} #{pc(cards[4], 1)}"
    puts "#{pc(cards[0], 2)} #{pc(cards[1], 2)} #{pc(cards[2], 2)} #{pc(cards[3], 2)} #{pc(cards[4], 2)}"
  end

  # print a player move which results in maximum score shift
  def look_ahead(board, current_hand, ai_hand)
    #n = NegamaxAgent.new(board, current_hand, ai_hand)
    #n_suggested_move = n.invoke
    #n_suggested_card = n_suggested_move.first
    #n_x = n_suggested_move[1]
    #n_y = n_suggested_move[2]
    #n_s = n_suggested_move[3]

    #puts "DEBUG: negamax suggested #{@player_hand.key(n_suggested_card)} @ #{n_x + 1}, #{n_y + 1} with score of #{n_s}"
    #return

    available_cards = current_hand.values.compact
    available_spaces = board.open_spaces
    possible_moves = available_cards.product(available_spaces)

    best_moves = []
    value_of_best_move = -10

    possible_moves.each do |card, space|
      x, y = space
      value = board.next_state(card, x, y).score
      if value > value_of_best_move
        best_moves = [[card, x, y]]
        value_of_best_move = value
      elsif value == value_of_best_move
      	best_moves << [card, x, y]
      end
    end

    chosen_move = best_moves.sample
    card, x, y = chosen_move

    puts "HINT: placing #{current_hand.key(card).rstrip} at #{x+1}, #{y+1} gives a good score of #{value_of_best_move}"
  end

  def determine_ai_move(board, ai_hand, player_hand)
    n = NegamaxAgent.new(board, ai_hand.values.compact, player_hand.values.compact)
    n_suggested_move = n.invoke
    n_suggested_card = n_suggested_move.first
    n_x = n_suggested_move[1]
    n_y = n_suggested_move[2]
    n_s = n_suggested_move[3]
    puts "DEBUG: negamax suggested #{ai_hand.key(n_suggested_card)} @ #{n_x}, #{n_y} with score #{n_s}"
    return [n_suggested_card, n_x, n_y]

    available_cards = ai_hand.values.compact
    available_spaces = board.open_spaces
    possible_moves = available_cards.product(available_spaces)

    best_moves = []
    value_of_best_move = 10

    possible_moves.each do |card, space|
      x, y = space
      future = board.next_state(card, x, y)
      value = retard_minimax(future, player_hand)

      if value < value_of_best_move
      	best_moves = [[card, x, y]]
      	value_of_best_move = value
      elsif value == value_of_best_move
      	best_moves << [card, x, y]
      end
    end

    best_moves.sort {|a, b| a.first.score <=> b.first.score}.last
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

  def player_move(turn)
  	if turn == 0
  	  system "clear"
  	  display_game
  	end
    
    #look_ahead(@board, @player_hand)
    #look_ahead(@board, @player_hand.values.compact, @ai_hand.values.compact)
    puts "Input: card_letter x y (ex. c 2 3)\n"
    input = gets.gsub(',' , '').rstrip
    letter, x, y = input.split
    key = @player_hand.keys.detect{|k| k[0] == letter.upcase}
    card = @player_hand[key]

    @board.make_move(card, x.to_i - 1, y.to_i - 1)
    @player_hand[key] = nil 

    system "clear"
    display_game
    puts "#{@board.open_spaces.count} spaces left. Enter to continue..."
    _ = gets
  end

  def ai_move(turn)
    system "clear"

    move = determine_ai_move(@board, @ai_hand, @player_hand)
    card, x, y = move
    @board.make_move(card, x, y)
    @ai_hand.delete(@ai_hand.key(card))

    display_game
    puts "AI played a card to #{x}, #{y}... #{@board.open_spaces.count} spaces left."
  end
end

r = Rules.instance
r.base = true
r.plus = true
r.same = true
r.combo = false
r.same_wall = false

t = TestGame.new
t.run