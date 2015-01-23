require 'singleton'

class Rules
  include Singleton

  attr_accessor :base
  attr_accessor :plus
  attr_accessor :same
  attr_accessor :same_wall
  attr_accessor :combo
end