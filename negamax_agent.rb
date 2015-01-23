class NegamaxAgent
  def initialize(board, max_hand, min_hand)
    @base_board = board
    @max_hand = max_hand
    @min_hand = min_hand
    @max_color = max_hand.first.color
    # looks like black magick. isn't. basically encapsulates the question
    #  "will min or max make the last move", which due to the nature of the
    #  game can be derived from the number of remaining spaces when the agent
    #  is to make a move.
    @polarity = board.open_spaces.count % 2 == 0 ? 1 : 0
    @d = []
  end

  def invoke
    negamax(@base_board, @max_hand, @min_hand, @polarity, turns, false)
  end

  def turns
    @base_board.open_spaces.count > 7 ? 4 : 5
  end

  def generate_moves(player_hand, spaces)
    if spaces.length == 9
      spaces = spaces.select{|x, y| x != 1 && y != 1}
      player_hand.product(spaces)
    else
      player_hand.product(spaces)
    end
  end

  #@return [card, x, y, score]
  def negamax(board, max_hand, min_hand, polarity, depth_left, debug=false)
    if depth_left == 0
      [nil, nil, nil, polarity * board.score(max_hand.first.color)]
    elsif board.open_spaces.length == 0
      [nil, nil, nil, polarity * board.score(max_hand.first.color)]
    else
      moves = generate_moves(max_hand, board.open_spaces)
      best_score_so_far = -100
      best_move_so_far = nil
      moves.each do |move|
      	card = move.first
      	x, y = move.last
      	future = board.next_state(card, x, y)
        result = negamax(future, min_hand, max_hand - [card], polarity * -1, depth_left - 1)
        score = -1 * result.last
        @d << [score, move] if debug
        if score > best_score_so_far
          best_score_so_far = score
          best_move_so_far = move
        end
      end

      if debug
        c = best_move_so_far.first
        x = best_move_so_far.last.first
        y = best_move_so_far.last.last
        f = board.next_state(c, x, y)
        h = max_hand - [c]
        binding.pry
      end

      [best_move_so_far.first, best_move_so_far.last.first, best_move_so_far.last.last, best_score_so_far]
    end

  end
end