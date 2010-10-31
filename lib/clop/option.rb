module Clop

  class Option

    def initialize(switches, argument_type, description)
      @switches = Array(switches)
      @argument_type = argument_type
      @description = description
    end

    attr_reader :switches, :argument_type, :description

    def attribute
      @attribute ||= long_switch.sub(/^--/, '').tr('-', '_')
    end
    
    def long_switch
      switches.find { |switch| switch =~ /^--/ }
    end

    def handles?(switch)
      switches.member?(switch)
    end
    
    def flag?
      @argument_type == :flag
    end
    
    def help
      lhs = switches.join(", ")
      lhs += " " + argument_type unless flag?
      [lhs, description]
    end
    
  end

end
