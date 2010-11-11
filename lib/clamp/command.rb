require 'clamp/command/declaration'
require 'clamp/errors'
require 'clamp/help'
require 'clamp/option/parsing'
require 'clamp/parameter/parsing'
require 'clamp/subcommand/execution'

module Clamp

  class Command

    def initialize(invocation_path, context = {})
      @invocation_path = invocation_path
      @context = context
    end

    # Returns the path used to invoke this command.
    attr_reader :invocation_path
    
    # Returns unconsumed command-line arguments.
    #
    # If you have declared positional parameters, this will typically be empty.
    def arguments
      @arguments
    end
    
    # attr_reader :arguments

    def parse(arguments)
      @arguments = arguments.dup
      parse_options
      parse_parameters
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
      self.class.help(invocation_path)
    end

    include Clamp::Option::Parsing
    include Clamp::Parameter::Parsing
    include Clamp::Subcommand::Execution

    protected
    
    attr_accessor :context
    attr_accessor :parent_command

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

      include Clamp::Command::Declaration
      include Help

      def run(invocation_path = $0, args = ARGV, context = {})
        begin 
          new(invocation_path, context).run(args)
        rescue Clamp::UsageError => e
          $stderr.puts "ERROR: #{e.message}"
          $stderr.puts ""
          $stderr.puts "See: '#{invocation_path} --help'"
          exit(1)
        rescue Clamp::HelpWanted => e
          puts e.command.help
        end
      end

    end

  end

end
