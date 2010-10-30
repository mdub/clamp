module Clop

  class Option

    def initialize(name, argument_type, description)
      @name = name
      @argument_type = argument_type
      @description = description
    end

    attr_reader :name, :argument_type, :description

    def attribute
      name.sub(/^--/, '')
    end

    def help
      "    %-19s %s" % ["#{name} #{argument_type}", description]
    end
    
  end

end
