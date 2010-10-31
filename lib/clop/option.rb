module Clop

  class Option

    def initialize(switch, argument_type, description)
      @switch = switch
      @argument_type = argument_type
      @description = description
    end

    attr_reader :switch, :argument_type, :description

    def attribute
      switch.sub(/^--/, '')
    end

    def reader
      attribute + (flag? ? "?" : "")
    end

    def writer
      attribute + "="
    end
    
    def help
      "%-31s %s" % ["#{switch} #{argument_type}", description]
    end
    
    def flag?
      @argument_type == :flag
    end
    
    def requires_argument?
      !flag?
    end
    
  end

end
