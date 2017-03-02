module Example
  class BarCommand < Clamp::Command
    def execute
      puts "Bar closed"
    end
  end
end
