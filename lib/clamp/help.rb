require 'stringio'

module Clamp

  module Help

    def usage(usage)
      @declared_usage_descriptions ||= []
      @declared_usage_descriptions << usage
    end

    attr_reader :declared_usage_descriptions

    def description=(description)
      @description = description.dup
      if @description =~ /^\A\n*( +)/
        indent = $1
        @description.gsub!(/^#{indent}/, '')
      end
      @description.strip!
    end

    attr_reader :description

    def derived_usage_description
      parts = parameters.map { |a| a.name }
      parts.unshift("[OPTIONS]")
      parts.join(" ")
    end

    def usage_descriptions
      declared_usage_descriptions || [derived_usage_description]
    end

    def help(invocation_path)
      help = StringIO.new
      help.puts "Usage:"
      usage_descriptions.each_with_index do |usage, i|
        help.puts "    #{invocation_path} #{usage}".rstrip
      end
      if description
        help.puts ""
        help.puts description.gsub(/^/, "  ")
      end
      if has_parameters?
        help.puts "\nParameters:"
        parameters.each do |parameter|
          render_help(help, parameter)
        end
      end
      if has_subcommands?
        help.puts "\nSubcommands:"
        recognised_subcommands.each do |subcommand|
          render_help(help, subcommand)
        end
      end
      help.puts "\nOptions:"
      recognised_options.each do |option|
        render_help(help, option)
      end
      help.string
    end
    
    private
    def render_help(help_io, help_source)
      detail_format = "    %-29s %s"
      title, description = help_source.help
      description.each_line do |line|
        help_io.puts detail_format % [title, line]
        # should just display the extra description lines indented with no title
        # do this by setting title to an empty string for subsequent lines after 1st
        title = ''
      end
    end

  end

end
