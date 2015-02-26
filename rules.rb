require 'singleton'

class Rules
  include Singleton

  attr_accessor :base
  attr_accessor :plus
  attr_accessor :same
  attr_accessor :same_wall
  attr_accessor :combo

  attr_accessor :order
  attr_accessor :reverse
  attr_accessor :fallen
  attr_accessor :descension
  attr_accessor :ascension
end

# ARE VIRTUAL ACES CREATED BY THE ASCENSION RULE AFFECTED BY FALLEN ACE
# ARE VIRTUAL ONES CREATED BY THE DESCENSION RULE AFFECTED BY FALLEN ACE