require 'spec_helper'
require 'stringio'

describe Clamp::Command do

  include OutputCapture

  def self.given_command(name, &block)
    before do
      @command = Class.new(Clamp::Command, &block).new(name)
    end
  end

  given_command("cmd") do

    def execute
      print arguments.inspect
    end

  end

  describe "#help" do

    it "describes usage" do
      @command.help.should include("Usage:\n    cmd\n")
    end

  end

  describe "#run" do

    before do
      @abc = %w(a b c)
      @command.run(@abc)
    end

    it "executes the #execute method" do
      stdout.should_not be_empty
    end

    it "provides access to the argument list" do
      stdout.should == @abc.inspect
    end

  end

  describe ".option" do

    it "declares option argument accessors" do
      @command.class.option "--flavour", "FLAVOUR", "Flavour of the month"
      @command.flavour.should == nil
      @command.flavour = "chocolate"
      @command.flavour.should == "chocolate"
    end

    describe "with type :flag" do

      before do
        @command.class.option "--verbose", :flag, "Be heartier"
      end

      it "declares a predicate-style reader" do
        @command.should respond_to(:verbose?)
        @command.should_not respond_to(:verbose)
      end

    end
    
    describe "with explicit :attribute_name" do

      before do
        @command.class.option "--foo", "FOO", "A foo", :attribute_name => :bar
      end

      it "uses the specified attribute_name name to name accessors" do
        @command.bar = "chocolate"
        @command.bar.should == "chocolate"
      end

      it "does not attempt to create the default accessors" do
        @command.should_not respond_to(:foo)
        @command.should_not respond_to(:foo=)
      end

    end

    describe "with :default value" do

      given_command("cmd") do
        option "--nodes", "N", "number of nodes", :default => 2
      end

      it "sets the specified default value" do
        @command.nodes.should == 2
      end

    end

    describe "with a block" do

      before do
        @command.class.option "--port", "PORT", "Port to listen on" do |port|
          Integer(port)
        end
      end

      it "uses the block to validate and convert the option argument" do
        lambda do
          @command.port = "blah"
        end.should raise_error(ArgumentError)
        @command.port = "1234"
        @command.port.should == 1234
      end

    end

  end
  
  describe "with options declared" do

    before do
      @command.class.option "--flavour", "FLAVOUR", "Flavour of the month"
      @command.class.option "--color", "COLOR", "Preferred hue"
      @command.class.option "--[no-]nuts", :flag, "Nuts (or not)"
    end

    describe "#parse" do

      describe "with an unrecognised option" do

        it "raises a UsageError" do
          lambda do
            @command.parse(%w(--foo bar))
          end.should raise_error(Clamp::UsageError)
        end

      end

      describe "with options" do

        before do
          @command.parse(%w(--flavour strawberry --nuts --color blue a b c))
        end

        it "maps the option values onto the command object" do
          @command.flavour.should == "strawberry"
          @command.color.should == "blue"
          @command.nuts?.should == true
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
          @command.parse(%w(--color blue -- --flavour strawberry))
          @command.arguments.should == %w(--flavour strawberry)
        end

      end

      describe "with --flag" do

        before do
          @command.parse(%w(--nuts))
        end

        it "sets the flag" do
          @command.nuts?.should be_true
        end

      end

      describe "with --no-flag" do

        before do
          @command.nuts = true
          @command.parse(%w(--no-nuts))
        end

        it "clears the flag" do
          @command.nuts?.should be_false
        end

      end

      describe "when option-writer raises an ArgumentError" do
        
        before do
          @command.class.class_eval do
            
            def color=(c)
              unless c == "black"
                raise ArgumentError, "sorry, we're out of #{c}"
              end
            end
            
          end
        end
          
        it "re-raises it as a UsageError" do
          lambda do
            @command.parse(%w(--color red))
          end.should raise_error(Clamp::UsageError, /^option '--color': sorry, we're out of red/)
        end

      end

    end

    describe "#help" do

      it "indicates that there are options" do
        @command.help.should include("cmd [OPTIONS]")
      end

      it "includes option details" do
        @command.help.should =~ %r(--flavour FLAVOUR +Flavour of the month)
        @command.help.should =~ %r(--color COLOR +Preferred hue)
      end

    end

  end

  describe ".argument" do

    it "declares option argument accessors" do
      @command.class.argument "FLAVOUR", "flavour of the month"
      @command.flavour.should == nil
      @command.flavour = "chocolate"
      @command.flavour.should == "chocolate"
    end

    describe "with a block" do

      before do
        @command.class.argument "PORT", "port to listen on" do |port|
          Integer(port)
        end
      end

      it "uses the block to validate and convert the argument" do
        lambda do
          @command.port = "blah"
        end.should raise_error(ArgumentError)
        @command.port = "1234"
        @command.port.should == 1234
      end

    end

  end

  describe "with arguments declared" do
    
    before do
      @command.class.argument "X", "x"
      @command.class.argument "Y", "y"
    end

    describe "#parse" do
      
      describe "with all arguments" do

        it "maps argument values onto the command object" do
          @command.parse(["crash", "bang"])
          @command.x.should == "crash"
          @command.y.should == "bang"
        end

      end

      describe "with insufficient arguments" do
        
        it "raises a UsageError" do
          lambda do
            @command.parse(["crash"])
          end.should raise_error(Clamp::UsageError, "no value provided for Y")
        end
        
      end

      describe "with too many arguments" do
        
        it "raises a UsageError" do
          pending
          lambda do
            @command.parse(["crash", "bang", "wallop"])
          end.should raise_error(Clamp::UsageError, "too many arguments")
        end
        
      end
      
    end
    
  end
  
  describe "with explicit usage" do

    given_command("blah") do

      usage "FOO BAR ..."

    end

    describe "#help" do

      it "includes the explicit usage" do
        @command.help.should include("blah FOO BAR ...\n")
      end

    end

  end

  describe "with multiple usages" do

    given_command("put") do

      usage "THIS HERE"
      usage "THAT THERE"

    end

    describe "#help" do

      it "includes both potential usages" do
        @command.help.should include("put THIS HERE\n")
        @command.help.should include("put THAT THERE\n")
      end

    end

  end

  describe ".run" do

    it "creates a new Command instance and runs it" do
      @xyz = %w(x y z)
      @command.class.run("cmd", @xyz)
      stdout.should == @xyz.inspect
    end

    describe "invoked with a context hash" do
      
      it "makes the context available within the command" do
        @command.class.class_eval do
          def execute
            print context[:foo]
          end
        end
        @command.class.run("xyz", [], :foo => "bar")
        stdout.should == "bar"        
      end
      
    end
    
    describe "when there's a UsageError" do

      before do

        @command.class.class_eval do
          def execute
            signal_usage_error "bad dog!"
          end
        end

        begin 
          @command.class.run("cmd", [])
        rescue SystemExit => e
          @system_exit = e
        end

      end

      it "outputs the error message" do
        stderr.should include "ERROR: bad dog!"
      end

      it "outputs help" do
        stderr.should include "See: 'cmd --help'"
      end

      it "exits with a non-zero status" do
        @system_exit.should_not be_nil
        @system_exit.status.should == 1
      end

    end

    describe "when help is requested" do

      it "outputs help" do
        @command.class.run("cmd", ["--help"])
        stdout.should include "Usage:"
      end

    end

  end

  describe "subclass" do
    
    before do
      @parent_command_class = Class.new(Clamp::Command) do
        option "--verbose", :flag, "be louder"
      end
      @derived_command_class = Class.new(@parent_command_class) do
        option "--iterations", "N", "number of times to go around"
      end
      @command = @derived_command_class.new("cmd")
    end
    
    it "inherits options from it's superclass" do
      @command.parse(["--verbose"])
      @command.should be_verbose
    end

  end
  
end
