require 'clamp/option'

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

    protected

    def execute_subcommand
      signal_usage_error "no subcommand specified" if arguments.empty?
      subcommand_name, *subcommand_args = arguments
      subcommand_class = find_subcommand_class(subcommand_name)
      subcommand = subcommand_class.new("#{name} #{subcommand_name}", context)
      subcommand.parent_command = self
      subcommand.run(subcommand_args)
    end

    private

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

      def declared_options
        @declared_options ||= []
      end

      def option(switches, argument_type, description, opts = {}, &block)
        option = Clamp::Option.new(switches, argument_type, description, opts)
        declared_options << option
        declare_option_reader(option)
        declare_option_writer(option, &block)
      end

      def has_options?
        !declared_options.empty?
      end

      HELP_OPTION = Clamp::Option.new("--help", :flag, "print help", :attribute_name => :help_requested)

      def standard_options
        [HELP_OPTION]
      end

      def acceptable_options
        declared_options + standard_options
      end

      def find_option(switch)
        acceptable_options.find { |o| o.handles?(switch) }
      end

      def declared_arguments
        @declared_arguments ||= []
      end

      def argument(name, description)
        declared_arguments << Argument.new(name, description)
      end

      def recognised_subcommands
        @recognised_subcommands ||= []
      end

      def subcommand(name, description, subcommand_class = nil, &block)
        if block
          if subcommand_class
            raise "no sense providing a subcommand_class AND an block"
          else
            subcommand_class = Class.new(Command, &block)
          end
        end
        recognised_subcommands << Subcommand.new(name, description, subcommand_class)
      end

      def has_subcommands?
        !recognised_subcommands.empty?
      end

      def find_subcommand(name)
        recognised_subcommands.find { |sc| sc.name == name }
      end

      def usage(usage)
        @declared_usage_descriptions ||= []
        @declared_usage_descriptions << usage
      end

      attr_reader :declared_usage_descriptions
      
      def derived_usage_description
        parts = declared_arguments.map { |a| a.name }
        parts.unshift("[OPTIONS]") if has_options?
        parts.unshift("SUBCOMMAND") if has_subcommands?
        parts.join(" ")
      end
      
      def usage_descriptions
        declared_usage_descriptions || [derived_usage_description]
      end

      def help(command_name)
        help = StringIO.new
        help.puts "Usage:"
        usage_descriptions.each_with_index do |usage, i|
          help.puts "    #{command_name} #{usage}".rstrip
        end
        detail_format = "    %-29s %s"
        unless declared_arguments.empty?
          help.puts "\nArguments:"
          declared_arguments.each do |argument|
            help.puts detail_format % argument.help
          end
        end
        unless recognised_subcommands.empty?
          help.puts "\nSubcommands:"
          subcommands.each do |subcommand|
            help.puts detail_format % subcommand.help
          end
        end
        if has_options?
          help.puts "\nOptions:"
          acceptable_options.each do |option|
            help.puts detail_format % option.help
          end
        end
        help.string
      end

      def run(name = $0, args = ARGV, context = {})
        begin 
          new(name, context).run(args)
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
          value = instance_variable_get("@#{option.attribute_name}")
          value = option.default_value if value.nil?
          value
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

  class Argument < Struct.new(:name, :description)

    def help
      [name, description]
    end

  end

  class Subcommand < Struct.new(:name, :description, :subcommand_class)

    def help
      [name, description]
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
