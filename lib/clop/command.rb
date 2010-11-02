require 'clop/argument'
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

        else
          option = find_option(switch)
          value = if option.flag?
            option.flag_value(switch)
          else
            arguments.shift
          end
          begin
            send("#{option.attribute}=", value)
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
      
      def option(switch, argument_type, description, &block)
        option = Clop::Option.new(switch, argument_type, description)
        options << option
        declare_option_reader(option)
        declare_option_writer(option, &block)
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
        rescue Clop::UsageError => e
          $stderr.puts "ERROR: #{e.message}"
          $stderr.puts ""
          $stderr.puts e.command.help
          exit(1)
        end
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

      def declare_option_writer(option, &block)
        define_method("#{option.attribute}=") do |value|
          if block
            value = block.call(value)
          end
          instance_variable_set("@#{option.attribute}", value)
        end
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
