module Clubhopping::Bar
  class ListCommand < Clamp::Command
    ENV["DEBUG"] && puts("Loaded ListCommand")

    def execute
      puts "All bars closed by the health inspector"
    end
  end
end
