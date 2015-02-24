require 'optparse'
require 'colorize'
require './negamax_agent.rb'
require './board.rb'
require './hand.rb'
require './benchmark.rb'
require './engine.rb'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ellone.rb [options]\n"
  opts.banner += "Example: ellone.rb -r 6 --second -pvp: play a game with no special rules, random hands, power level 6, going second, vs. ai"

  opts.on("-n", "--benchmark [DEPTH=8]", "ignore all other options and check how long negamax takes to resolve on your machine.") do |v|
    options[:benchmark_mode] = true
    options[:benchmark_depth] = v ? v.to_i : 8
  end

  #setup
  opts.on("-f", "--fast", "have the player pick the AI's first move in PVP mode") do |v|
    options[:first_manual] = true
  end

  options[:saved_hand] = true
  opts.on("-o", "--open", "with a saved red hand and a selected blue hand (default)") do |v|
   #options[:saved_hand] = true
  end
  opts.on("-r", "--random [POWER]", "with randomly generated hands") do |v|
    options[:random_hands] = true
    options[:power_level] = v ? v.to_i : 3
    options[:saved_hand] = false
  end
  opts.on("-a", "--allopen", "with selected hands for both players") do |v|
    options[:open] = true
    options[:saved_hand] = false
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
  r.ascension = true

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

puts "Should the blue player (manual input/your opponent) take the first move? Y/N"
puts " (i.e are you playing second in the FF14 client)"
choice = gets
if ['Y', 'y', 'yes', 'YES'].include?(choice.strip)
  options[:switch] = false
else
  options[:switch] = true
end

unless options[:random_hands]
  c = CardList.new
  names = c.all_card_names
  blue_hand = []
  red_hand = []
  p names

    while blue_hand.length < 5
      puts "Filling #{"blue (human)".colorize(:light_blue)} player's hand; please enter a card name.\n"
      choice = gets.downcase.strip
      card_name = names.detect{|n| n.downcase == choice}
      if card_name.nil?
        substring_matches = names.select{|n| n.downcase.include?(choice)}
        if substring_matches.empty?
          puts "That doesn't match any known cards...\n".colorize(:red)
        elsif substring_matches.length > 1
          puts "#{choice} substring is ambiguous; options are #{substring_matches}"
        else
          card_name = substring_matches.first
        end
      end

      if card_name
        blue_hand << [card_name, c.card_with_name(card_name)]
        puts "Successfully added card; hand is " + "#{blue_hand.map(&:first)}\n".colorize(:green)
      end
    end

  if options[:saved_hand]
    preselected = File.open("red_hand.txt").read
    preselected.each_line do |name|
      card_name = names.detect{|n| n.downcase == name.downcase.strip}
      raise "tried to load unknown card #{name}" if card_name.nil?
      red_hand << [card_name, c.card_with_name(card_name)] 
    end
  else
    while red_hand.length < 5
      puts "Filling #{"red (AI)".colorize(:red)} player's hand; please enter a card name.\n"
      choice = gets.downcase.strip
      card_name = names.detect{|n| n.downcase == choice}
      if card_name.nil?
        substring_matches = names.select{|n| n.downcase.include?(choice)}
        if substring_matches.empty?
          puts "That doesn't match any known cards...\n".colorize(:red)
        elsif substring_matches.length > 1
          puts "#{choice} substring is ambiguous; options are #{substring_matches}"
        else
          card_name = substring_matches.first
        end
      end

      if card_name
        red_hand << [card_name, c.card_with_name(card_name)]
        puts "Successfully added card; hand is " + "#{red_hand.map(&:first)}\n".colorize(:green)
      end
    end
  end

  options[:blue_hand] = blue_hand
  options[:red_hand] = red_hand
end

e = Engine.new(options)
e.run