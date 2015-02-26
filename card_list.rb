require 'pry'
require 'json'
require 'yaml'
require './card.rb'

class CardList
  def initialize
    @ranks = YAML.load_file("ff14_cards.yaml")
  end

  def parse
    @ranks = {}
    data = File.read("ff14_cards.txt")
    data.each_line do |l|
      tokens = l.split
      stars = tokens.pop.to_i
      west = tokens.pop.to_i
      south = tokens.pop.to_i
      east = tokens.pop.to_i
      north = tokens.pop.to_i
      name = tokens.join(" ")
      @ranks[stars] = {} if @ranks[stars].nil?
      @ranks[stars][name] = {"north" => north, "south" => south, "east" => east, "west" => west, "type" => name}
    end
    binding.pry
  end

  def all_card_names
    names = []
    @ranks.each do |_, cards|
      cards.each do |name, _|
        names << name
      end
    end
    names
  end

  def card_from_hash(h)
    c = Card.new(h["north"], h["south"], h["east"], h["west"], h["type"])
  end

  def card_with_name(name)
    @ranks.each do |_, cards|
      return card_from_hash(cards[name]) if cards[name]
    end
  end

  def card_with_rank(rank)
    choices = @ranks[rank.to_i]
    card_name = choices.keys.sample
    [card_name, card_from_hash(choices[card_name])]
  end
end