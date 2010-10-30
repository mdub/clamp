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
        case (option_argument = arguments.shift)

        when /\A--\z/
          break

        when /^(--\w+|-\w)/
          option = get_option($1)
          send("#{option.attribute}=", arguments.shift)
          
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

    def usage
      "#{name} [OPTIONS]"
    end
    
    def help
      help = StringIO.new
      help.puts "usage: #{usage}"
      help.puts ""
      help.puts "  OPTIONS"
      self.class.options.each do |option|
        help.puts "    #{option.help}"
      end
      help.string
    end

    private

    def get_option(option_string)
      option = self.class.find_option(option_string)
      signal_usage_error "Unrecognised option '#{option_string}'" unless option
      option
    end

    def signal_usage_error(message)
      e = UsageError.new(message, self)
      e.set_backtrace(caller)
      raise e
    end
    
    class << self
    
      def options
        @options ||= []
      end
      
      def option(name, argument_type, description)
        option = Clop::OptionHandler.new(name, argument_type, description)
        options << option
        attr_accessor option.attribute
      end
      
      def find_option(name)
        options.find { |o| o.name == name }
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
