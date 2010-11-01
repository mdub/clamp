module Clop

  class Option

    def initialize(switches, argument_type, description)
      @switches = Array(switches)
      @argument_type = argument_type
      @description = description
    end

    attr_reader :switches, :argument_type, :description

    def attribute
      @attribute ||= long_switch.sub(/^--(\[no-\])?/, '').tr('-', '_')
    end
    
    def long_switch
      switches.find { |switch| switch =~ /^--/ }
    end

    def handles?(switch)
      recognised_switches.member?(switch)
    end

    def flag?
      @argument_type == :flag
    end
    
    def flag_value(switch)
      !(switch =~ /^--no-(.*)/ && switches.member?("--\[no-\]#{$1}"))
    end
    
    def help
      lhs = switches.join(", ")
      lhs += " " + argument_type unless flag?
      [lhs, description]
    end

    private
    
    def recognised_switches
      switches.map do |switch|
        if switch =~ /^--\[no-\](.*)/
          ["--#{$1}", "--no-#{$1}"]
        else
          switch
        end
      end.flatten
    end
    
  end

end
