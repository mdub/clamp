require 'spec_helper'

class SimpleCommand < Clop::Command

  def execute
    @execution = {
      :arguments => arguments.dup
    }
  end

  attr_reader :execution
  
  def executed?
    !!@execution
  end
  
end

describe Clop::Command do

  before do
    @command = SimpleCommand.new("simple")
  end

  describe "#run" do

    describe "with no args" do

      before do
        @command.run([])
      end

      it "executes the #execute method" do
        @command.should be_executed
      end

    end

    describe "with args" do

      before do
        @command.run(%w(a b c))
      end

      it "provides access to the argument list" do
        @command.execution[:arguments].should == %w(a b c)
      end

    end

  end

end
