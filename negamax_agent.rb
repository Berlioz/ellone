class NegamaxAgent
  def initialize(board, max_hand, min_hand, difficulty = 8, debug = false)
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
    @debug = debug
    if @debug
      @nodes = 0
      @leaves = 0
      @prunes = 0
    end
  end

  # if in debug mode, returns [total_nodes_expanded, leaves_expanded, pruned_subtrees]
  def get_stats
    @debug ? [@nodes, @leaves, @prunes] : nil
  end

  def invoke(corner_hack = false)
    @corner_hack = true if corner_hack
    negamax(@base_board, @max_hand, @min_hand, @polarity, turns, -100, 100)
  end

  # depth function
  def turns
    #@base_board.open_spaces.count > 7 ? [2, @difficulty].max : @difficulty
    @difficulty
  end

  #@return [card, [x, y]]
  def generate_moves(player_hand, spaces)
    player_hand = [player_hand.first] if Rules.instance.order
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
  def negamax(board, max_hand, min_hand, polarity, depth_left, alpha, beta)
    @nodes += 1 if @debug
    skip = false
    skipped_score = nil

    if depth_left == 0
      @leaves += 1 if @debug
      [nil, nil, nil, polarity * (board.score(max_hand.first.color) + max_hand.length - min_hand.length)]
    elsif board.open_spaces.length == 0
      @leaves += 1 if @debug
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
          @prunes += 1 if @debug
          break
        end
      end

      best_move = tiebreaker(best_moves_so_far, board)
      [best_move.first, best_move.last.first, best_move.last.last, best_score_so_far]
    end

  end
end