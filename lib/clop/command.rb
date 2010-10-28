module Clop
  
  class Command
    
    def initialize(name)
      @name = name
    end
    
    attr_reader :name

    def run(arguments)
      execute
    end

    def execute
      raise "you need to define #execute"
    end
    
  end
  
end
