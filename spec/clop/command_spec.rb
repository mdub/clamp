require 'spec_helper'
require 'stringio'

describe Clop::Command do

  before do
    $stdout = @out = StringIO.new
  end

  after do
    $stdout = STDOUT
  end

  def output
    @out.string
  end

  def self.given_command(&block)
    before do
      @command = Class.new(Clop::Command, &block).new("anon")
    end
  end
  
  describe "simple" do

    given_command do

      def execute
        print arguments.inspect
      end

    end
    
    describe "#run" do
      
      before do
        @abc = %w(a b c)
        @command.run(@abc)
      end

      it "executes the #execute method" do
        output.should_not == ""
      end

      it "provides access to the argument list" do
        output.should == @abc.inspect
      end

    end

  end
  
end