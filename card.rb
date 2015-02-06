require 'pry'
require 'colorize'

class Card
  COLORS = {0 => :none, 1 => :light_blue, 2 => :red}
  OPPOSITES = {:north => :south, :south => :north, :east => :west, :west => :east}

  attr_reader :north
  attr_reader :south
  attr_reader :east
  attr_reader :west
  attr_accessor :color

  def initialize(north, south, east, west, color=0)
    @north = north
    @south = south
    @east = east
    @west = west
    @color = color
  end

  def self.init_random(color=0)
    Card.new(1 + rand(10), 1 + rand(10), 1 + rand(10), 1 + rand(10), color)
  end

  def flips?(other_card, direction) #direction is from self to other_card
    my_face = self.send(direction)
    opponent_face = other_card.send(OPPOSITES[direction])
    my_face > opponent_face
  end

  def plus_sum(other_card, direction)
    my_face = self.send(direction)
    opponent_face = other_card.send(OPPOSITES[direction])
    my_face + opponent_face
  end

  def same_match?(other_card, direction)
    my_face = self.send(direction)
    opponent_face = other_card.send(OPPOSITES[direction])
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