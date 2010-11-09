require 'clamp/argument_support'
require 'clamp/help_support'
require 'clamp/option_support'
require 'clamp/subcommand_support'

module Clamp

  class Command

    def initialize(name, context = {})
      @name = name
      @context = context
    end

    attr_reader :name
    attr_reader :arguments

    attr_accessor :context
    attr_accessor :parent_command

    def parse(arguments)
      @arguments = arguments.dup
      parse_options
      parse_arguments
    end

    # default implementation
    def execute
      if self.class.has_subcommands?
        execute_subcommand
      else
        raise "you need to define #execute"
      end
    end

    def run(arguments)
      parse(arguments)
      execute
    end

    def help
      self.class.help(name)
    end

    private

    def parse_options
      while arguments.first =~ /^-/

        switch = arguments.shift
        break if switch == "--"

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
    
    def parse_arguments
      self.class.declared_arguments.each do |argument|
        value = arguments.shift
        begin
          send("#{argument.attribute_name}=", value)
        rescue ArgumentError => e
          signal_usage_error "option '#{argument.name}': #{e.message}"
        end
      end
    end
    
    def execute_subcommand
      signal_usage_error "no subcommand specified" if arguments.empty?
      subcommand_name = arguments.shift
      subcommand_class = find_subcommand_class(subcommand_name)
      subcommand = subcommand_class.new("#{name} #{subcommand_name}", context)
      subcommand.parent_command = self
      subcommand.run(arguments)
    end

    def find_option(switch)
      self.class.find_option(switch) || 
      signal_usage_error("Unrecognised option '#{switch}'")
    end

    def find_subcommand(name)
      self.class.find_subcommand(name) || 
      signal_usage_error("No such sub-command '#{name}'")
    end

    def find_subcommand_class(name)
      subcommand = find_subcommand(name)
      subcommand.subcommand_class if subcommand
    end

    def signal_usage_error(message)
      e = UsageError.new(message, self)
      e.set_backtrace(caller)
      raise e
    end

    def help_requested=(value)
      raise Clamp::HelpWanted.new(self)
    end

    class << self

      include OptionSupport
      include ArgumentSupport
      include SubcommandSupport
      include HelpSupport

      def run(name = $0, args = ARGV, context = {})
        begin 
          new(name, context).run(args)
        rescue Clamp::UsageError => e
          $stderr.puts "ERROR: #{e.message}"
          $stderr.puts ""
          $stderr.puts "See: '#{name} --help'"
          exit(1)
        rescue Clamp::HelpWanted => e
          puts e.command.help
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
