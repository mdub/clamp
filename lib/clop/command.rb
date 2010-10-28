module Clop
  
  class Command
    
    def initialize(name)
      @name = name
    end
    
    attr_reader :name
    attr_reader :arguments
    
    def run(arguments)
      @arguments = arguments
      execute
    end

    def execute
      raise "you need to define #execute"
    end
    
  end
  
end
