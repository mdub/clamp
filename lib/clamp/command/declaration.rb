require 'clamp/option/declaration'
require 'clamp/parameter/declaration'
require 'clamp/subcommand/declaration'

module Clamp
  class Command
    
    module Declaration
      include Clamp::Option::Declaration
      include Clamp::Parameter::Declaration
      include Clamp::Subcommand::Declaration
    end

  end
end
