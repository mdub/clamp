require 'clamp/help'
require 'clamp/option/declaration'
require 'clamp/option/parsing'
require 'clamp/positional_argument/declaration'
require 'clamp/positional_argument/parsing'
require 'clamp/subcommand/declaration'
require 'clamp/subcommand/execution'

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
      parse_positional_arguments
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

    include Option::Parsing
    include PositionalArgument::Parsing
    include Subcommand::Execution
    
    private

    def signal_usage_error(message)
      e = UsageError.new(message, self)
      e.set_backtrace(caller)
      raise e
    end

    def help_requested=(value)
      raise Clamp::HelpWanted.new(self)
    end

    class << self

      include Option::Declaration
      include PositionalArgument::Declaration
      include Subcommand::Declaration
      include Help

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
