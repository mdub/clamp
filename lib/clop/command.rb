require 'clop/option_handler'

module Clop
  
  class Command
    
    def initialize(name)
      @name = name
    end
    
    attr_reader :name
    attr_reader :arguments

    def parse(arguments)
      while arguments.first =~ /^-/
        case (option = arguments.shift)

        when /\A--\z/
          break

        when /^(--\w+|-\w)/
          option_handler = find_option_handler($1)
          send("#{option_handler.attribute}=", arguments.shift)
          
        else
          raise "can't handle #{option}"
          
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

    def usage
      "#{name} [OPTIONS]"
    end
    
    def help
      help = StringIO.new
      help.puts "usage: #{usage}"
      help.puts ""
      help.puts "  OPTIONS"
      self.class.option_handlers.each do |option_handler|
        help.puts "    #{option_handler.help}"
      end
      help.string
    end

    private

    def find_option_handler(option)
      handler = self.class.find_option_handler(option)
      signal_usage_error "Unrecognised option '#{option}'" unless handler
      handler
    end

    def signal_usage_error(message)
      e = UsageError.new(message, self)
      e.set_backtrace(caller)
      raise e
    end
    
    class << self
    
      def option_handlers
        @option_handlers ||= []
      end
      
      def option(option, argument_type, description)
        handler = Clop::OptionHandler.new(option, argument_type, description)
        option_handlers << handler
        attr_accessor handler.attribute
      end
      
      def find_option_handler(option)
        option_handlers.find { |o| o.option == option }
      end
      
    end
        
  end
  
  class UsageError < StandardError
    
    def initialize(message, command)
      super(message)
      @command = command
    end

    attr_reader :command
    
  end
  
end
