require 'spec_helper'

class SimpleCommand < Clop::Command

  def executed?
    @executed
  end

  def execute
    @executed = true
  end

end

describe Clop::Command do

  before do
    @command = SimpleCommand.new("simple")
  end

  describe "#run", "with no args" do

    before do
      @command.run([])
    end

    it "executes the #execute method" do
      @command.should be_executed
    end

  end

end
