module Clamp
  class Option

    module Parsing

      protected

      def parse_options
        while remaining_arguments.first =~ /^-/

          switch = remaining_arguments.shift
          break if switch == "--"

          option = find_option(switch)
          value = option.extract_value(switch, remaining_arguments)

          begin
            send("#{option.attribute_name}=", value)
          rescue ArgumentError => e
            signal_usage_error "option '#{switch}': #{e.message}"
          end

        end
      end

      private

      def find_option(switch)
        self.class.find_option(switch) || 
        signal_usage_error("Unrecognised option '#{switch}'")
      end

    end

  end
end