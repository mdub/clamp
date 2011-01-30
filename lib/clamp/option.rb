require 'clamp/attribute'

module Clamp

  class Option < Attribute

    def initialize(switches, type, description, options = {})
      @switches = Array(switches)
      @type = type
      @description = description
      if options.has_key?(:attribute_name)
        @attribute_name = options[:attribute_name].to_s 
      end
      if options.has_key?(:default)
        @default_value = options[:default]
      end
    end

    attr_reader :switches, :type

    def attribute_name
      @attribute_name ||= long_switch.sub(/^--(\[no-\])?/, '').tr('-', '_')
    end
    
    def long_switch
      switches.find { |switch| switch =~ /^--/ }
    end

    def handles?(switch)
      recognised_switches.member?(switch)
    end

    def flag?
      @type == :flag
    end
    
    def flag_value(switch)
      !(switch =~ /^--no-(.*)/ && switches.member?("--\[no-\]#{$1}"))
    end

    def read_method
      if flag?
        super + "?"
      else
        super
      end
    end
    
    def extract_value(switch, arguments)
      if flag?
        flag_value(switch)
      else
        arguments.shift
      end
    end
    
    def help_lhs
      lhs = switches.join(", ")
      lhs += " " + type unless flag?
      lhs
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
