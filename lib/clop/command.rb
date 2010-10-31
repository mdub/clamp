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

    def help
      self.class.help.gsub("__COMMAND__", name)
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
      
      def has_options?
        !options.empty?
      end
      
      def find_option(switch)
        options.find { |o| o.switch == switch }
      end

      def usage(usage)
        @usages ||= []
        @usages << usage
      end

      def derived_usage
        "[OPTIONS]" if has_options?
      end
      
      def help
        help = StringIO.new
        usages = @usages || [derived_usage]
        usages.each_with_index do |usage, i|
          prefix = (i.zero? ? "usage:" : "      ")
          help.puts "#{prefix} __COMMAND__ #{usage}".rstrip
        end
        help.puts ""
        help.puts "  OPTIONS"
        options.each do |option|
          help.puts "    #{option.help}"
        end
        help.string
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
