require 'pry'
require './card.rb'

class CardList
  def initialize
    @ranks = {}
    open("card_list.txt").readlines.each do |m|
      card = m.split(/\s\s+/)
      rank = card[0]
      name = card[1]
      north = card[3] == "A" ? 10 : card[3].to_i
      east = card[4] == "A" ? 10 : card[4].to_i
      south = card[5] == "A" ? 10 : card[5].to_i
      west = card[6] == "A" ? 10 : card[6].to_i
      @ranks[rank.to_i] = {} if @ranks[rank.to_i].nil?

      @ranks[rank.to_i][name] = {:north => north, :south => south, :east => east, :west => west}  
    end
  end

  def card_from_hash(h)
    Card.new(h[:north], h[:south], h[:east], h[:west])
  end

  def card_with_rank(rank)
  	#binding.pry
    choices = @ranks[rank]
    card_name = choices.keys.sample
    [card_name, card_from_hash(choices[card_name])]
  end
end