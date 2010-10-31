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

  def self.given_command(name, &block)
    before do
      @command = Class.new(Clop::Command, &block).new(name)
    end
  end

  describe "simple" do

    given_command("simple") do

      def execute
        print arguments.inspect
      end

    end

    describe "#parse" do

      it "sets arguments" do
        @command.parse(%w(a b c))
        @command.arguments.should == %w(a b c)
      end

      describe "with an unrecognised option" do

        it "raises a UsageError" do
          lambda do
            @command.parse(%w(--foo bar))
          end.should raise_error(Clop::UsageError)
        end

      end

    end

    describe "#run" do

      before do
        @abc = %w(a b c)
        @command.run(@abc)
      end

      it "executes the #execute method" do
        output.should_not be_empty
      end

      it "provides access to the argument list" do
        output.should == @abc.inspect
      end

    end

  end

  describe "with an option declared" do

    given_command("icecream") do

      option "--flavour", "FLAVOUR", "Flavour of the month"

    end

    it "has accessors for the option" do
      @command.should respond_to(:flavour)
      @command.should respond_to(:flavour=)
    end

    describe "option value" do

      it "is nil by default" do
        @command.flavour.should == nil
      end

      it "can be modified" do
        @command.flavour = "chocolate"
        @command.flavour.should == "chocolate"
      end

    end

    describe "#parse" do

      describe "with a value for the option" do

        before do
          @command.parse(%w(--flavour strawberry a b c))
        end

        it "extracts the option value" do
          @command.flavour.should == "strawberry"
        end

        it "retains unconsumed arguments" do
          @command.arguments.should == %w(a b c)
        end

      end

      describe "with option-like things beyond the arguments" do

        it "treats them as positional arguments" do
          @command.parse(%w(a b c --flavour strawberry))
          @command.arguments.should == %w(a b c --flavour strawberry)
        end

      end

      describe "with an option terminator" do

        it "considers everything after the terminator to be an argument" do
          @command.parse(%w(-- --flavour strawberry))
          @command.arguments.should == %w(--flavour strawberry)
        end

      end

    end

    describe "#help" do

      it "includes option details" do
        @command.help.should =~ %r(--flavour FLAVOUR +Flavour of the month)
      end

    end

  end

  describe "with a flag option declared" do

    given_command("hello") do

      option "--verbose", :flag, "Be heartier"

    end

    it "has a predicate reader" do
      @command.should respond_to(:verbose?)
    end

    it "does not have a non-predicate reader" do
      @command.should_not respond_to(:verbose)
    end

    it "defaults to false" do
      @command.should_not be_verbose
    end

    describe "#parse" do

      describe "with option" do

        before do
          @command.parse(%w(--verbose foo))
        end

        it "sets the option" do
          @command.should be_verbose
        end

        it "does not consume an argument" do
          @command.arguments.should == %w(foo)
        end

      end

    end

  end

end