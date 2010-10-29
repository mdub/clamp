require 'clop/option'

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

    private

    def get_option(option_string)
      option = self.class.options[option_string]
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
        @options ||= {}
      end
      
      def option(name)
        option = Clop::Option.new(name)
        options["--#{name}"] = option
        attr_accessor option.attribute
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
