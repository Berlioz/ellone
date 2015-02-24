require 'optparse'
require 'colorize'
require './negamax_agent.rb'
require './board.rb'
require './hand.rb'
require './benchmark.rb'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ellone.rb [options]\n"
  opts.banner += "Example: ellone.rb -r 6 --second -pvp: play a game with no special rules, random hands, power level 6, going second, vs. ai"

  opts.on("-n", "--benchmark [DEPTH=8]", "ignore all other options and check how long negamax takes to resolve on your machine.") do |v|
    options[:benchmark_mode] = true
    options[:benchmark_depth] = v ? v.to_i : 8
  end

  #setup
  opts.on("-2", "--second", "play second instead of first in PVP mode") do |v|
    options[:switch] = true
  end
  options[:random_hands] = true
  options[:power_level] = 6
  opts.on("-r", "--random [POWER]", "with randomly generated hands (default)") do |v|
    options[:random_hands] = true
    options[:power_level] = v ? v.to_i : 6
  end
  opts.on("-o", "--open", "with selected hands for both players") do |v|
    options[:random_hands] = false
    options[:open] = true
  end

  #ff14 rules
  opts.on("-O", "--order", "with ORDER rule") do |v|
    options[:order] = true
  end  
  opts.on("-R", "--reverse", "with REVERSE rule") do |v|
    options[:reverse] = true
  end
  opts.on("-F", "--fallen", "with FALLEN rule") do |v|
    options[:fallen] = true
  end
  opts.on("-A", "--ascension", "with ASCENSION rule") do |v|
    options[:ascension] = true
  end
  opts.on("-D", "--descension", "with DESCENSION rule") do |v|
    options[:descension] = true
  end

  #ff8 rules
  opts.on("-p", "--plus", "with PLUS rule") do |v|
    options[:plus] = true
  end
  opts.on("-s", "--same", "with SAME rule") do |v|
    options[:same] = true
  end
  opts.on("-w", "--wall", "with WALL rule") do |v|
    options[:same_wall] = true
  end
  opts.on("-c", "--combo", "with COMBO rule") do |v|
    options[:combo] = true
  end

  #operating mode
  options[:mode] = :pvp
  opts.on("-m", "--mode [MODE]", "sets the mode [pvp, test, manual]. Default pvp") do |v|
    options[:mode] = :pvp if v.downcase == "pvp"
    options[:mode] = :manual if v.downcase == "manual"
    options[:mode] = :test if v.downcase == "test"
  end

  options[:depth] = 8
  opts.on("-d", "--difficulty [DEPTH]", "AI evaluation depth (2-8) WARNING: hopelessly bad pre-horizon play below 8 right now") do |v|
    i = v.to_i
    options[:depth] = [[2, v.to_i].max, 8].min
  end
end.parse!

if options[:benchmark_mode]
  r = Rules.instance
  r.base = true
  r.plus = true
  r.same = true
  r.same_wall = true
  r.combo = true

  blue_hand = Hand.from_random(1)
  red_hand = Hand.from_random(2)
  b = Benchmark.new(blue_hand, red_hand, options[:benchmark_depth])
  b.run
  exit!
end

r = Rules.instance
r.base = true
r.plus = true if options[:plus]
r.same = true if options[:same]
r.same_wall = true if options[:same_wall]
r.combo = true if options[:combo]
r.order = true if options[:order]
r.reverse = true if options[:reverse]
r.fallen = true if options[:fallen]
r.ascension = true if options[:ascension]
r.descension = true if options[:descension]

if options[:open]
  c = CardList.new
  names = c.all_card_names
  blue_hand = []
  red_hand = []
  p names

  while blue_hand.length < 5
    puts "Filling blue player's hand; please enter a card name.\n"
    choice = gets.downcase.strip
    card_name = names.detect{|n| n.downcase == choice}
    if card_name.nil?
      puts "That doesn't match any known cards...\n".colorize(:red)
    else
      blue_hand << [card_name, c.card_with_name(card_name)]
      puts "Successfully added card; hand is " + "#{blue_hand.map(&:first)}\n".colorize(:green)
    end
  end

  while red_hand.length < 5
    puts "Filling red player's hand; please enter a card name.\n"
    choice = gets.downcase.strip
    card_name = names.detect{|n| n.downcase == choice}
    if card_name.nil?
      puts "That doesn't match any known cards...\n".colorize(:red)
    else
      red_hand << [card_name, c.card_with_name(card_name)]
      puts "Successfully added card; hand is " + "#{red_hand.map(&:first)}\n".colorize(:green)
    end
  end
  options[:blue_hand] = blue_hand
  options[:red_hand] = red_hand
end

class Ellone
  def initialize(options)
    @options = options
    @board = Board.new
    if options[:random_hands]
      @blue_hand = Hand.from_random(1)
      @red_hand = Hand.from_random(2)
    else
      @blue_hand = Hand.new(1, options[:blue_hand])
      @red_hand = Hand.new(2, options[:red_hand])
    end
    @depth = options[:depth]
  end

  def print_game_state
    puts @board
    puts @blue_hand.to_s(@board)
    puts @red_hand.to_s(@board)
  end

  def run
    if @options[:mode] == :test
      run_test_game
    elsif @options[:mode] == :pvp
      run_pvp_game
    elsif @options[:mode] == :manual
      run_manual_game
    end
  end

  def run_test_game
    0.upto(8).each do |turn|
      color = (turn % 2) + 1
      ai_turn(color)
    end
    score_for_blue = @board.score + @blue_hand.cards.length - @red_hand.cards.length
    puts "Final score is: " + "#{score_for_blue < 0 ? '' : '+'}#{score_for_blue}".colorize(score_for_blue >= 0 ? :green : :red)
  end

  def run_pvp_game
    0.upto(8).each do |turn|
      color = (turn % 2) + 1
      human_color = @options[:switch] ? 2 : 1
      if color == human_color
        human_turn(color)
      else
        ai_turn(color)
      end
    end
    score_for_blue = @board.score + @blue_hand.cards.length - @red_hand.cards.length
    puts "Final score is: " + "#{score_for_blue < 0 ? '' : '+'}#{score_for_blue}".colorize(score_for_blue >= 0 ? :green : :red)
  end

  def run_manual_game
    0.upto(8).each do |turn|
      color = (turn % 2) + 1
      human_turn(color)
    end
    score_for_blue = @board.score + @blue_hand.cards.length - @red_hand.cards.length
    puts "Final score is: " + "#{score_for_blue < 0 ? '' : '+'}#{score_for_blue}".colorize(score_for_blue >= 0 ? :green : :red)
  end

  private

  def ai_turn(to_play)
    puts "AI is thinking...(difficulty #{@options[:depth]})"
    n = NegamaxAgent.new(@board, get_active_hand(to_play).cards, get_passive_hand(to_play).cards, @options[:depth])
    n_card, n_x, n_y, n_s = n.invoke
    system "clear"

    @board.make_move(n_card, n_x, n_y)
    cardname = get_active_hand(to_play).name_of_card(n_card)
    get_active_hand(to_play).remove_card(n_card)
    @ongoing_game = true
    print_game_state
    puts "AI played #{cardname} to #{n_x}, #{n_y}... #{@board.open_spaces.count} spaces left."
    puts "DEBUG: AI believes it can achieve a score of #{n_s} with optimal play"
  end

  def human_turn(to_play)
    print_game_state unless @ongoing_game
    hand = get_active_hand(to_play)

    player_move = nil
    while player_move.nil?
      player_move = get_input(hand)
    end
    card, x, y = player_move

    @board.make_move(card, x - 1, y - 1)
    hand.remove_card(card)
    @ongoing_game = true

    system "clear"
    print_game_state
    puts "#{@board.open_spaces.count} spaces left. Enter to continue..."
    _ = $stdin.gets
  end

  def get_active_hand(active_player)
    active_player == 1 ? @blue_hand : @red_hand
  end

  def get_passive_hand(active_player)
    active_player == 2 ? @blue_hand : @red_hand
  end

  def get_input(hand)
    puts "Input: card_substring x y (ex. red_giant 2 3)\n"
    input = $stdin.gets.gsub(',' , '').rstrip
    key, x, y = input.split
    if key == "debug"
      binding.pry
      nil
    end
    key = key.gsub("_", " ")
    unless key && x && y
      puts "Malformed expression...\n"
      return nil
    end
    card_name = hand.names.detect{|name| name.downcase.include?(key.downcase)}
    card = hand.card_with_name(card_name)
    unless @board.open_spaces.include?([x.to_i - 1, y.to_i - 1]) && card
      puts "Illegal move...\n"
      return nil
    end
    [card, x.to_i, y.to_i]
  end

end

e = Ellone.new(options)
e.run