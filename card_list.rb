require 'pry'
require 'json'
require './card.rb'

class CardList
  def initialize
    @ranks = JSON.parse(File.read("card_list.json"))
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
    choices = @ranks[rank.to_s]
    card_name = choices.keys.sample
    [card_name, card_from_hash(choices[card_name])]
  end
end