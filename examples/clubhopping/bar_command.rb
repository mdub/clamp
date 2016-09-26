module Clubhopping
  class BarCommand < Clamp::Command

    subcommand "list", "List open bars", "Clubhopping::Bar::ListCommand" => File.join(__dir__, 'list_command')

    def execute
    end
  end
end
