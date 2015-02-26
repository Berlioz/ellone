require './card.rb'
require './rules.rb'
require 'msgpack'

class Board
  def initialize(board=nil)
    if board
      @board = board
    else
      @board = [ [nil, nil, nil],
                 [nil, nil, nil],
                 [nil, nil, nil] ]
    end
    @wall_card = Card.new(10, 10, 10, 10, "w@ll")
  end

  # in lieu of an actual serialization scheme, have an extremely lazy pastiche
  def clone()
    struct = @board.map{|row| row.map{|card| card.nil? ? nil : card.serialize}}
    new_data = MessagePack.unpack(MessagePack.pack(struct))
    Board.new(new_data.map{|row| row.map{|s| s.nil? ? nil : Card.from_ary(s)}})
  end

  def wall_adjacency(x, y)
    rv = {}
    rv[:north] = y != 0 ? @board[x][y - 1] : @wall_card
    rv[:south] = y != 2 ? @board[x][y + 1] : @wall_card
    rv[:east]  = x != 2 ? @board[x + 1][y] : @wall_card
    rv[:west]  = x != 0 ? @board[x - 1][y] : @wall_card
    rv
  end

  def adjacency(x, y)
    rv = {}
    rv[:north] = @board[x][y - 1] unless y == 0
    rv[:south] = @board[x][y + 1] unless y == 2
    rv[:east]  = @board[x + 1][y] unless x == 2
    rv[:west]  = @board[x - 1][y] unless x == 0
    rv
  end

  def score(color=1)
    rv = 0
    @board.flatten.compact.each do |c|
      rv += 1 if c.color == color
      rv -= 1 if c.color != color
    end
    rv
  end

  def spaces_left?
    @board.flatten.compact < 9
  end

  def open_spaces
    [[0,0], [0,1], [0,2], [1,0], [1, 1], [1,2], [2,0], [2,1], [2,2]].select {|x, y| @board[x][y].nil?}
  end

  def next_state(card, x, y)
    new_board = self.clone
    new_board.make_move(card, x, y)
    new_board
  end

  def make_move(card, x, y)
    @board[x][y] = card
    resolve(x, y)
  end

  def resolve(x, y)
    rank_captures(x,y) if Rules.instance.base
    plus_captures(x,y) if Rules.instance.plus
    same_captures(x,y) if (Rules.instance.same && ! Rules.instance.same_wall)
    same_wall_captures(x,y) if Rules.instance.same_wall
  end

  # resolve captures due to the card at x,y being placed
  # @arg chain if ture, this is a Combo capture and should continue to Combo
  def rank_captures(x, y, chain = false)
    placed_card = @board[x][y]
    asc = ascension(placed_card)
    adjacencies = adjacency(x, y)
    adjacencies.each do |direction, other_card|
      next unless other_card
      if other_card.color != placed_card.color
        if placed_card.flips?(other_card, direction, asc, ascension(other_card))
          other_card.color = placed_card.color
          combo_off(x, y, direction, other_card) if chain
        end
      end
    end
  end

  # resolve Plus captures due to the card at x,y being placed
  def plus_captures(x,y)
    side_sums = {}
    placed_card = @board[x][y]
    asc = ascension(placed_card)
    adjacencies = adjacency(x, y)

    # determine the sum in all directions
    adjacencies.each do |direction, other_card|
      next unless other_card
      sum = placed_card.plus_sum(other_card, direction, asc, ascension(other_card))
      side_sums[sum] ? side_sums[sum] << other_card : side_sums[sum] = [other_card]
    end

    # {13 => [card_a, card_b], 6 => [card_c]}
    side_sums.values.select{|matches| matches.length > 1}.each do |cards_to_flip|
      cards_to_flip.each do |card|
        next if card.color == placed_card.color
        card.color = placed_card.color
        if Rules.instance.combo
          direction = adjacencies.key(card)
          combo_off(x, y, direction, card)
        end
      end
    end
  end

  def same_captures(x,y)
    matches = []
    placed_card = @board[x][y]
    asc = ascension(placed_card)
    adjacencies = adjacency(x, y)

    # determine the sum in all directions
    adjacencies.each do |direction, other_card|
      next unless other_card
      match = placed_card.same_match?(other_card, direction, asc, ascension(other_card))
      if match
        matches << other_card
      end
    end

    if matches.length > 1
      matches.each do |card|
        next if card.color == placed_card.color
        card.color = placed_card.color
        if Rules.instance.combo
          direction = adjacencies.key(card)
          combo_off(x, y, direction, card)
        end
      end
    end
  end

  def same_wall_captures(x,y)
    matches = []
    placed_card = @board[x][y]
    asc = ascension(placed_card)
    adjacencies = wall_adjacency(x,y)
    # determine the sum in all directions
    adjacencies.each do |direction, other_card|
      next unless other_card
      match = placed_card.same_match?(other_card, direction, asc, ascension(other_card))
      if match
        matches << other_card
      end
    end

    if matches.length > 1
      matches.each do |card|
        next if card.color == placed_card.color || card == @wall_card
        card.color = placed_card.color
        if Rules.instance.combo
          direction = adjacencies.key(card)
          combo_off(x, y, direction, card)
        end
      end
    end
  end

  def combo_off(x, y, direction, card)
    case direction
      when :north
        y -= 1
      when :south
        y += 1
      when :east
        x += 1
      when :west
        x -= 1
    end

    # at this point, we know that our base is card at x, y
    rank_captures(x, y, true)
  end

  def ascension(card)
    return 0 unless (Rules.instance.ascension || Rules.instance.descension)
    count = @board.flatten.select{|c| c && c.type == card.type}.count
    count = count * -1 if Rules.instance.descension
    count
  end

  # [  A  ] [  5  ]
  # [ 5 9 ] [ 3 8 ]
  # [  6  ] [  6  ]
  #
  # [  7  ] [  2  ] etc
  def pc(x, y, row)
    @board[x][y].nil? ? "[     ]" : @board[x][y].row(row)
  end

  def to_s
    rv =  " X    1       2       3    \n"
    rv += "Y  #{pc(0, 0, 0)} #{pc(1, 0, 0)} #{pc(2, 0, 0)}\n"
    rv += " 1 #{pc(0, 0, 1)} #{pc(1, 0, 1)} #{pc(2, 0, 1)}\n"
    rv += "   #{pc(0, 0, 2)} #{pc(1, 0, 2)} #{pc(2, 0, 2)}\n"
    rv += "\n"
    rv += "   #{pc(0, 1, 0)} #{pc(1, 1, 0)} #{pc(2, 1, 0)}\n"
    rv += " 2 #{pc(0, 1, 1)} #{pc(1, 1, 1)} #{pc(2, 1, 1)}\n"
    rv += "   #{pc(0, 1, 2)} #{pc(1, 1, 2)} #{pc(2, 1, 2)}\n"
    rv += "\n"
    rv += "   #{pc(0, 2, 0)} #{pc(1, 2, 0)} #{pc(2, 2, 0)}\n"
    rv += " 3 #{pc(0, 2, 1)} #{pc(1, 2, 1)} #{pc(2, 2, 1)}\n"
    rv += "   #{pc(0, 2, 2)} #{pc(1, 2, 2)} #{pc(2, 2, 2)}\n"
    rv
  end
end