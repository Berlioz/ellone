require 'pry'
require 'colorize'

class Card
  COLORS = {0 => :none, 1 => :light_blue, 2 => :red}
  OPPOSITES = {:north => :south, :south => :north, :east => :west, :west => :east}

  attr_accessor :north
  attr_accessor :south
  attr_accessor :east
  attr_accessor :west
  attr_accessor :color
  attr_reader :type

  def self.from_ary(ary)
    Card.new(ary[0], ary[1], ary[2], ary[3], ary[4], ary[5])
  end

  def initialize(north, south, east, west, type=nil, color=0)
    @north = north
    @south = south
    @east = east
    @west = west
    @color = color
    @type = type
  end

  def bound(n)
    [1, [10, n].min].max
  end

  def serialize
    [@north, @south, @east, @west, @type, @color]
  end

  def self.init_random(color=0)
    Card.new(1 + rand(10), 1 + rand(10), 1 + rand(10), 1 + rand(10), color)
  end

  def flips?(other_card, direction, my_ascension, other_ascension) #direction is from self to other_card
    my_face = bound(self.send(direction) + my_ascension)
    opponent_face = bound(other_card.send(OPPOSITES[direction]) + other_ascension)
    #binding.pry
    if Rules.instance.fallen && (!Rules.instance.reverse) && (my_face == 1) && (opponent_face == 10)
      true
    elsif Rules.instance.reverse
      my_face < opponent_face
    else
      my_face > opponent_face
    end
  end

  def plus_sum(other_card, direction, my_ascension, other_ascension)
    my_face = bound(self.send(direction) + my_ascension)
    opponent_face = bound(other_card.send(OPPOSITES[direction]) + other_ascension)
    my_face + opponent_face
  end

  def same_match?(other_card, direction, my_ascension, other_ascension)
    my_face = bound(self.send(direction) + my_ascension)
    opponent_face = bound(other_card.send(OPPOSITES[direction]) + other_ascension)
    my_face == opponent_face ? my_face : nil
  end

  def score
    @north + @south + @east + @west
  end

  def a(i)
    i == 10 ? "A" : i.to_s
  end

  def to_s
    "[  #{a @north}  ]\n".colorize(COLORS[@color]) +
        "[ #{a @west} #{a @east} ]\n".colorize(COLORS[@color]) +
        "[  #{a @south}  ]".colorize(COLORS[@color])
  end

  def row(row)
    if row == 0
      "[  #{a @north}  ]".colorize(COLORS[@color])
    elsif row == 1
      "[ #{a @west} #{a @east} ]".colorize(COLORS[@color])
    elsif row == 2
      "[  #{a @south}  ]".colorize(COLORS[@color])
    else
      raise ArgumentError
    end
  end
end