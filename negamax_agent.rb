class NegamaxAgent
  def initialize(board, max_hand, min_hand, difficulty = 8)
    @base_board = board
    @max_hand = max_hand
    @min_hand = min_hand
    @max_color = max_hand.first.color
    # looks like black magick. isn't. basically encapsulates the question
    #  "will min or max make the last move", which due to the nature of the
    #  game can be derived from the number of remaining spaces when the agent
    #  is to make a move.
    @polarity = board.open_spaces.count % 2 == 0 ? 1 : -1
    @difficulty = difficulty
  end

  def invoke
  	debug = @base_board.open_spaces.length == 1 ? true : false
    negamax(@base_board, @max_hand, @min_hand, @polarity, turns, -100, 100, debug)
  end

  # depth function
  def turns
   #@base_board.open_spaces.count > 7 ? [2, @difficulty].max : @difficulty
   @difficulty
  end

  #@return [card, [x, y]]
  def generate_moves(player_hand, spaces)
    if spaces.length == 9
      spaces = spaces.select{|x, y| x != 1 && y != 1}
      player_hand.product(spaces)
    else
      player_hand.product(spaces)
    end
  end

  # W E L P
  def tiebreaker(candidates, board)
  	candidates.first
  end

  #@return [card, x, y, score]
  def negamax(board, max_hand, min_hand, polarity, depth_left, alpha, beta, debug=false)
  	#binding.pry if debug
    skip = false
    skipped_score = nil

    if depth_left == 0
      [nil, nil, nil, polarity * (board.score(max_hand.first.color) + max_hand.length - min_hand.length)]
    elsif board.open_spaces.length == 0
      [nil, nil, nil, polarity * (board.score(max_hand.first.color) + max_hand.length - min_hand.length)]
    else
      moves = generate_moves(max_hand, board.open_spaces)
      best_score_so_far = -100
      best_moves_so_far = []
      moves.each do |move|
      	card = move.first
      	x, y = move.last
      	future = board.next_state(card, x, y)
        result = negamax(future, min_hand, max_hand - [card], polarity * -1, depth_left - 1, -1 * beta, -1 * alpha)
        score = -1 * result.last
        if score > best_score_so_far
          best_score_so_far = score
          best_moves_so_far = [move]
        elsif score == best_score_so_far
          best_moves_so_far << move
        end

        alpha = [alpha, best_score_so_far].max
        if alpha >= beta
          break
        end
      end

      best_move = tiebreaker(best_moves_so_far, board)
      [best_move.first, best_move.last.first, best_move.last.last, best_score_so_far]
    end

  end
end