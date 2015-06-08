module Clamp
  module Option

    module Parsing

      protected

      def parse_options

        while remaining_arguments.first =~ /\A-/

          switch = remaining_arguments.shift
          break if switch == "--"

          case switch
          when /\A(-\w)(.+)\z/m # combined short options
            switch = $1
            if find_option(switch).flag?
              remaining_arguments.unshift("-" + $2)
            else
              remaining_arguments.unshift($2)
            end
          when /\A(--[^=]+)=(.*)\z/m
            switch = $1
            remaining_arguments.unshift($2)
          end

          option = find_option(switch)
          value = option.extract_value(switch, remaining_arguments)

          begin
            option.of(self).take(value)
          rescue ArgumentError => e
            signal_usage_error Clamp.message(:option_argument_error, :switch => switch, :message => e.message)
          end

        end

        # Fill in gap from environment
        self.class.recognised_options.each do |option|
          option.of(self).default_from_environment
        end

        # Verify that all required options are present
        self.class.recognised_options.each do |option|
          # If this option is required and the value is nil, there's an error.
          if option.required? and send(option.attribute_name).nil?
            if option.environment_variable
              message = Clamp.message(:option_or_env_required, :option => option.switches.first, :env => option.environment_variable)
            else
              message = Clamp.message(:option_required, :option => option.switches.first)
            end
            signal_usage_error message
          end
        end
      end

      private

      def find_option(switch)
        self.class.find_option(switch) ||
        signal_usage_error(Clamp.message(:unrecognised_option, :switch => switch))
      end

    end

  end
end
