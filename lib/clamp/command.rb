require 'clamp/argument'
require 'clamp/option'

module Clamp
  
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

        else
          option = find_option(switch)
          value = if option.flag?
            option.flag_value(switch)
          else
            arguments.shift
          end
          begin
            send("#{option.attribute_name}=", value)
          rescue ArgumentError => e
            signal_usage_error "option '#{switch}': #{e.message}"
          end
          
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
      
      def option(switches, argument_type, description, opts = {}, &block)
        option = Clamp::Option.new(switches, argument_type, description, opts)
        self.options << option
        declare_option_reader(option)
        declare_option_writer(option, &block)
      end
      
      def help_option(switches = ["-h", "--help"])
        option(switches, :flag, "print help", :attribute_name => :help_requested) do
          raise Clamp::HelpWanted.new(self)
        end
      end
        
      def has_options?
        !options.empty?
      end
      
      def find_option(switch)
        options.find { |o| o.handles?(switch) }
      end

      def usage(usage)
        @usages ||= []
        @usages << usage
      end

      def arguments
        @arguments ||= []
      end
      
      def argument(name, description)
        arguments << Argument.new(name, description)
      end

      def derived_usage
        parts = arguments.map { |a| a.name }
        parts.unshift("[OPTIONS]") if has_options?
        parts.join(" ")
      end
      
      def help
        help = StringIO.new
        help.puts "Usage:"
        usages = @usages || [derived_usage]
        usages.each_with_index do |usage, i|
          help.puts "    __COMMAND__ #{usage}".rstrip
        end
        detail_format = "    %-29s %s"
        unless arguments.empty?
          help.puts "\nArguments:"
          arguments.each do |argument|
            help.puts detail_format % [argument.name, argument.description]
          end
        end
        unless options.empty?
          help.puts "\nOptions:"
          options.each do |option|
            help.puts detail_format % option.help
          end
        end
        help.string
      end
      
      def run(name = $0, args = ARGV)
        begin 
          new(name).run(args)
        rescue Clamp::UsageError => e
          $stderr.puts "ERROR: #{e.message}"
          $stderr.puts ""
          $stderr.puts e.command.help
          exit(1)
        rescue Clamp::HelpWanted => e
          puts e.command.help
        end
      end

      private
      
      def declare_option_reader(option)
        reader_name = option.attribute_name
        reader_name += "?" if option.flag?
        define_method(reader_name) do
          instance_variable_get("@#{option.attribute_name}") || option.default_value
        end
      end

      def declare_option_writer(option, &block)
        define_method("#{option.attribute_name}=") do |value|
          if block
            value = instance_exec(value, &block)
          end
          instance_variable_set("@#{option.attribute_name}", value)
        end
      end
      
    end
        
  end
  
  class Error < StandardError
    
    def initialize(message, command)
      super(message)
      @command = command
    end

    attr_reader :command
    
  end

  # raise to signal incorrect command usage
  class UsageError < Error; end
  
  # raise to request usage help
  class HelpWanted < Error
    
    def initialize(command)
      super("I need help", command)
    end
    
  end
  
end
