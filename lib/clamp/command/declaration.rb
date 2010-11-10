require 'clamp/option/declaration'
require 'clamp/parameter/declaration'
require 'clamp/subcommand/declaration'

module Clamp
  class Command
    
    module Declaration
      include Option::Declaration
      include Parameter::Declaration
      include Subcommand::Declaration
    end

  end
end
