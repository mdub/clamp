module Clop

  class Option

    def initialize(switch, argument_type, description)
      @switch = switch
      @argument_type = argument_type
      @description = description
    end

    attr_reader :switch, :argument_type, :description

    def attribute
      switch.sub(/^--/, '').tr('-', '_')
    end
    
    def flag?
      @argument_type == :flag
    end
    
    def help
      lhs = switch
      lhs += " " + argument_type unless flag?
      [lhs, description]
    end
    
  end

end
