require './card_list.rb'

class Hand
  attr_accessor :hand

  def self.from_random(color, strength = nil)
    generated_hand = Hand.random_cards(color, strength)
    Hand.new(color, generated_hand)
  end

  def initialize(color, hand)
    @hand = hand
    @hand.each do |name, card|
      card.color = color
    end
  end

  def self.random_cards(color, strength = nil)
    card_list = CardList.new
    rv = []
    generate_rank_spread(strength).each do |rank|
      name, card = card_list.card_with_rank(rank)
      card.color = color
      rv << [name, card]
    end
    rv
  end

  # @return [Array] integers from 1-10 representing card ranks,
  # with a statistical distribution intended to make for an interesting game
  def self.generate_rank_spread(center=nil)
    def self.r(center)
      rng = rand(100)
      if rng < 10
        [center - 2, 1].max
      elsif rng < 35
        [center - 1, 1].max
      elsif rng < 65
        center
      elsif rng < 90
        [center + 1, 5].min
      else
        [center + 2, 5].min
      end
    end
    center = center || [1,2,3,4,5].sample
    [r(center), r(center), r(center), r(center), r(center)]
  end

  def to_s(current_board = nil)
    def pc(card, row)
      card.nil? ? "       " : card.row(row)
    end
    def card_type_line(card, current_board)
      return "" if card.nil?
      return "#{card.type}" if current_board.nil?
      ascension = current_board.ascension(card)
      ascension = (ascension >= 0 ? ("+" + ascension.to_s) : ascension.to_s)
      "#{card.type} (#{ascension})"
    end
    names = @hand.map(&:first).map {|name| '%-15.15s' % name}
    types = @hand.map(&:last).map{|card| '%-15.15s' % card_type_line(card, current_board)} if (Rules.instance.ascension || Rules.instance.descension)
    cards = @hand.map(&:last)
    # a normal card is 7 characters across
    interstitial_length = 9
    i = ' ' * interstitial_length
    rv =  "#{names[0]} #{names[1]} #{names[2]} #{names[3]} #{names[4]}\n".colorize(:green)
    rv += "#{types[0]} #{types[1]} #{types[2]} #{types[3]} #{types[4]}\n" if (Rules.instance.ascension || Rules.instance.descension)
    rv += "#{pc(cards[0], 0)}#{i}#{pc(cards[1], 0)}#{i}#{pc(cards[2], 0)}#{i}#{pc(cards[3], 0)}#{i}#{pc(cards[4], 0)}\n"
    rv += "#{pc(cards[0], 1)}#{i}#{pc(cards[1], 1)}#{i}#{pc(cards[2], 1)}#{i}#{pc(cards[3], 1)}#{i}#{pc(cards[4], 1)}\n"
    rv += "#{pc(cards[0], 2)}#{i}#{pc(cards[1], 2)}#{i}#{pc(cards[2], 2)}#{i}#{pc(cards[3], 2)}#{i}#{pc(cards[4], 2)}\n"
    rv
  end

  def cards
    @hand.map(&:last).compact
  end

  def names
    @hand.select{|name, card| card != nil}.map(&:first)
  end

  def card_with_name(name)
    @hand.detect{|n, card| n.downcase == name.downcase && card}.last rescue nil
  end

  def name_of_card(card)
    @hand.detect{|n, c| c == card}.first rescue nil
  end

  # KILL ME
  def remove_card(element)
    if element.is_a? Card
      @hand.each do |pair|
        name, card = pair
        if card == element
          pair[1] = nil
          return
        end
      end
    else
      @hand.each do |pair|
        name, card = pair
        if name == element
          pair[1] = nil
          return
        end
      end
    end
  end

  def empty?
    @hand.map(&:last).compact.empty?
  end
end