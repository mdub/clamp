module Clop
  
  class Command
    
    def initialize(name)
      @name = name
    end
    
    attr_reader :name
    attr_reader :arguments

    def parse(arguments)
      while arguments.first =~ /^-/
        case (option_argument = arguments.shift)

        when /\A--\z/
          break

        when /^--(\w+)/
          option_name = $1
          send("#{option_name}=", arguments.shift)
          
        else
          raise "can't handle #{option_argument}"
          
        end
      end
      @arguments = arguments
    end
    
    def execute
      raise "you need to define #execute"
    end
    
    def run(arguments)
      parse(arguments)
      execute
    end
    
    class << self
    
      def option(name)
        attr_accessor name
      end
      
    end
    
  end
  
end
