require 'clamp/errors'
require 'clamp/help'
require 'clamp/option/declaration'
require 'clamp/option/parsing'
require 'clamp/parameter/declaration'
require 'clamp/parameter/parsing'
require 'clamp/subcommand/declaration'
require 'clamp/subcommand/execution'

module Clamp

  # {Command} models a shell command.  Each command invocation is a new object.
  # Command options and parameters are represented as attributes 
  # (see {Command::Declaration}).
  #
  # The main entry-point is {#run}, which uses {#parse} to populate attributes based 
  # on an array of command-line arguments, then calls {#execute} (which you provide)
  # to make it go.
  #
  class Command

    # Create a command execution.
    #
    # @param [String] invocation_path the path used to invoke the command
    # @param [Hash] context additional data the command may need
    #
    def initialize(invocation_path, context = {})
      @invocation_path = invocation_path
      @context = context
    end

    # @return [String] the path used to invoke this command
    #
    attr_reader :invocation_path
    
    # @return [Array<String>] unconsumed command-line arguments
    #
    def remaining_arguments
      @remaining_arguments
    end

    # Parse command-line arguments.
    #
    # @param [Array<String>] arguments command-line arguments
    # @return [Array<String>] unconsumed arguments
    #
    def parse(arguments)
      @remaining_arguments = arguments.dup
      parse_options
      parse_parameters
      @remaining_arguments
    end

    # Run the command, with the specified arguments.
    #
    # This calls {#parse} to process the command-line arguments, 
    # then delegates to {#execute}.
    #
    # @param [Array<String>] arguments command-line arguments
    #
    def run(arguments)
      parse(arguments)
      execute
    end

    # Execute the command (assuming that all options/parameters have been set).
    # 
    # This method is designed to be overridden in sub-classes.
    #
    def execute
      if self.class.has_subcommands?
        execute_subcommand
      else
        raise "you need to define #execute"
      end
    end

    # @return [String] usage documentation for this command
    #
    def help
      self.class.help(invocation_path)
    end

    include Clamp::Option::Parsing
    include Clamp::Parameter::Parsing
    include Clamp::Subcommand::Execution

    protected
    
    attr_accessor :context

    private

    def signal_usage_error(message, with_help = false)
      e = if with_help
            UsageErrorWithHelp.new(message, self)
          else
            UsageError.new(message, self)
          end
      e.set_backtrace(caller)
      raise e
    end

    def help_requested=(value)
      raise Clamp::HelpWanted.new(self)
    end

    class << self

      include Clamp::Option::Declaration
      include Clamp::Parameter::Declaration
      include Clamp::Subcommand::Declaration
      include Help

      # Create an instance of this command class, and run it.
      #
      # @param [String] invocation_path the path used to invoke the command
      # @param [Array<String>] arguments command-line arguments
      # @param [Hash] context additional data the command may need
      # 
      def run(invocation_path = File.basename($0), arguments = ARGV, context = {})
        begin 
          new(invocation_path, context).run(arguments)
        rescue Clamp::UsageErrorWithHelp => e
          $stderr.puts "ERROR: #{e.message}\n\n"
          puts e.command.help
          exit(1)
        rescue Clamp::UsageError => e
          $stderr.puts "ERROR: #{e.message}"
          $stderr.puts ""
          $stderr.puts "See: '#{e.command.invocation_path} --help'"
          exit(1)
        rescue Clamp::HelpWanted => e
          puts e.command.help
        end
      end

    end

  end

end
