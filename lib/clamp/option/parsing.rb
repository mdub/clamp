module Clamp
  module Option

    module Parsing

      protected

      def parse_options

        argument_stop_index = remaining_arguments.index('--')
        if argument_stop_index
          after_break_params = remaining_arguments.slice!(argument_stop_index..-1)
          after_break_params.shift
        else
          after_break_params = []
        end

        remaining_params = []

        until remaining_arguments.empty?
          switch = remaining_arguments.shift

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
          when /\A[^-]/
            remaining_params.push(switch)
            next
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

        remaining_arguments.replace(remaining_params + after_break_params)
      end

      private

      def find_option(switch)
        self.class.find_option(switch) ||
        signal_usage_error(Clamp.message(:unrecognised_option, :switch => switch))
      end

    end

  end
end
