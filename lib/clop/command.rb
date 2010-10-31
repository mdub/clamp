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
        case (switch = arguments.shift)

        when /\A--\z/
          break

        when /^(--\w+|-\w)/
          option = find_option($1)
          value = option.flag? ? true : arguments.shift
          send("#{option.attribute}=", value)
          
        else
          raise "can't handle #{switch}"
          
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

    def find_option(switch)
      self.class.find_option(switch) || 
      signal_usage_error("Unrecognised option '#{switch}'")
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
      
      def option(switch, argument_type, description)
        option = Clop::Option.new(switch, argument_type, description)
        options << option
        declare_option_reader(option)
        declare_option_writer(option)
      end
      
      def find_option(switch)
        options.find { |o| o.switch == switch }
      end
      
      private
      
      def declare_option_reader(option)
        reader_name = option.attribute
        reader_name += "?" if option.flag?
        class_eval <<-RUBY
        def #{reader_name}
          @#{option.attribute}
        end
        RUBY
      end

      def declare_option_writer(option)
        class_eval <<-RUBY
        def #{option.attribute}=(value)
          @#{option.attribute} = value
        end
        RUBY
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
