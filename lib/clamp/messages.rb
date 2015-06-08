module Clamp

  module Messages

    def messages=(new_messages)
      messages.merge!(new_messages)
    end

    def message(key, options={})
      format_string(messages.fetch(key), options)
    end

    def clear_messages!
      init_default_messages
    end

    private

    DEFAULTS = {
      :too_many_arguments => "too many arguments",
      :option_required => "option '%<option>s' is required",
      :option_or_env_required => "option '%<option>s' (or env %<env>s) is required",
      :option_argument_error => "option '%<switch>s': %<message>s",
      :parameter_argument_error => "parameter '%<param>s': %<message>s",
      :env_argument_error => "$%<env>s: %<message>s",
      :unrecognised_option => "Unrecognised option '%<switch>s'",
      :no_such_subcommand => "No such sub-command '%<name>s'",
      :no_value_provided => "no value provided",
      :usage_heading => "Usage",
      :parameters_heading => "Parameters",
      :subcommands_heading => "Subcommands",
      :options_heading => "Options"
    }

    def messages
      unless defined?(@messages)
        init_default_messages
      end
      @messages
    end

    def init_default_messages
      @messages = DEFAULTS.clone
    end

    begin

      ("%{foo}" % {:foo => "bar"}) # test Ruby 1.9 string interpolation

      def format_string(format, params = {})
        format % params
      end

    rescue ArgumentError

      # string formatting for ruby 1.8
      def format_string(format, params = {})
        array_params = format.scan(/%[<{]([^>}]*)[>}]/).collect do |name|
          name = name[0]
          params[name.to_s] || params[name.to_sym]
        end
        format.gsub(/%[<]([^>]*)[>]/, '%').gsub(/%[{]([^}]*)[}]/, '%s') % array_params
      end

    end

  end

  extend Messages

end
