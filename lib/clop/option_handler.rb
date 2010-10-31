module Clop

  class OptionHandler

    def initialize(option, argument_type, description)
      @option = option
      @argument_type = argument_type
      @description = description
    end

    attr_reader :option, :argument_type, :description

    def attribute
      option.sub(/^--/, '')
    end

    def help
      "%-31s %s" % ["#{option} #{argument_type}", description]
    end
    
    def flag?
      @argument_type == :flag
    end
    
    def requires_argument?
      !flag?
    end
    
  end

end
