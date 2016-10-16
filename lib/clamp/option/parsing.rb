module Clamp
  module Option

    module Parsing

      protected

      def parse_options
        set_options_from_command_line
        default_options_from_environment
        verify_required_options_are_set
      end

      private

      def set_options_from_command_line
        while remaining_arguments.first && remaining_arguments.first.start_with?("-")

          switch = remaining_arguments.shift
          break if switch == "--"

          case switch
          when /\A(-\w)(.+)\z/m # combined short options
            switch = Regexp.last_match(1)
            if find_option(switch).flag?
              remaining_arguments.unshift("-" + Regexp.last_match(2))
            else
              remaining_arguments.unshift(Regexp.last_match(2))
            end
          when /\A(--[^=]+)=(.*)\z/m
            switch = Regexp.last_match(1)
            remaining_arguments.unshift(Regexp.last_match(2))
          end

          option = find_option(switch)
          value = option.extract_value(switch, remaining_arguments)

          begin
            option.of(self).take(value)
          rescue ArgumentError => e
            signal_usage_error Clamp.message(:option_argument_error, :switch => switch, :message => e.message)
          end

        end
      end

      def default_options_from_environment
        self.class.recognised_options.each do |option|
          option.of(self).default_from_environment
        end
      end

      def verify_required_options_are_set
        self.class.recognised_options.each do |option|
          # If this option is required and the value is nil, there's an error.
          next unless option.required? && send(option.attribute_name).nil?
          if option.environment_variable
            message = Clamp.message(:option_or_env_required,
                                    :option => option.switches.first,
                                    :env => option.environment_variable)
          else
            message = Clamp.message(:option_required,
                                    :option => option.switches.first)
          end
          signal_usage_error message
        end
      end

      def find_option(switch)
        self.class.find_option(switch) ||
          signal_usage_error(Clamp.message(:unrecognised_option, :switch => switch))
      end

    end

  end
end
