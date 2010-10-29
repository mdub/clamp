module Clop

  class Option

    def initialize(name)
      @name = name
    end

    attr_reader :name

    def attribute
      name
    end

  end

end
