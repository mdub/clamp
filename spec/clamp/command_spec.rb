
require 'spec_helper'

describe Clamp::Command do

  extend CommandFactory
  include OutputCapture

  given_command("cmd") do

    def execute
      puts "Hello, world"
    end

  end

  describe "#help" do

    it "describes usage" do
      command.help.should =~ /^Usage:\n    cmd.*\n/
    end

  end

  describe "#run" do

    before do
      command.run([])
    end

    it "executes the #execute method" do
      stdout.should_not be_empty
    end

  end

  describe ".option" do

    it "declares option argument accessors" do
      command.class.option "--flavour", "FLAVOUR", "Flavour of the month"
      command.flavour.should == nil
      command.flavour = "chocolate"
      command.flavour.should == "chocolate"
    end

    describe "with type :flag" do

      before do
        command.class.option "--verbose", :flag, "Be heartier"
      end

      it "declares a predicate-style reader" do
        command.should respond_to(:verbose?)
        command.should_not respond_to(:verbose)
      end

    end

    describe "with explicit :attribute_name" do

      before do
        command.class.option "--foo", "FOO", "A foo", :attribute_name => :bar
      end

      it "uses the specified attribute_name name to name accessors" do
        command.bar = "chocolate"
        command.bar.should == "chocolate"
      end

      it "does not attempt to create the default accessors" do
        command.should_not respond_to(:foo)
        command.should_not respond_to(:foo=)
      end

    end

    describe "with default method" do

      before do
        command.class.option "--port", "PORT", "port"
        command.class.class_eval do
          def default_port
            4321
          end
        end
      end

      it "sets the specified default value" do
        command.port.should == 4321
      end

    end

    describe "with :default value" do

      before do
        command.class.option "--port", "PORT", "port to listen on", :default => 4321
      end

      it "declares default method" do
        command.default_port.should == 4321
      end

      describe "#help" do

        it "describes the default value" do
          command.help.should include("port to listen on (default: 4321)")
        end

      end

    end

    describe "with :multivalued" do

      before do
        command.class.option "--flavour", "FLAVOUR", "flavour(s)", :multivalued => true, :attribute_name => :flavours
      end

      it "defaults to empty array" do
        command.flavours.should == []
      end

      it "supports multiple values" do
        command.parse(%w(--flavour chocolate --flavour vanilla))
        command.flavours.should == %w(chocolate vanilla)
      end

      it "generates a single-value appender method" do
        command.append_to_flavours("mud")
        command.append_to_flavours("pie")
        command.flavours.should == %w(mud pie)
      end

      it "generates a multi-value setter method" do
        command.append_to_flavours("replaceme")
        command.flavours = %w(mud pie)
        command.flavours.should == %w(mud pie)
      end

    end

    describe "with :environment_variable" do

      before do
        command.class.option "--port", "PORT", "port to listen on", :default => 4321, :environment_variable => "PORT" do |value|
          value.to_i
        end
      end

      context "when no environment variable is present" do

        before do
          ENV.delete("PORT")
        end

        it "uses the default" do
          command.parse([])
          command.port.should == 4321
        end

      end

      context "when environment variable is present" do

        before do
          ENV["PORT"] = "12345"
        end

        it "uses the environment variable" do
          command.parse([])
          command.port.should == 12345
        end

        context "and a value is specified on the command-line" do

          it "uses command-line value" do
            command.parse(%w(--port 1500))
            command.port.should == 1500
          end

        end

      end

      describe "#help" do

        it "describes the default value and env usage" do
          command.help.should include("port to listen on (default: $PORT, or 4321)")
        end

      end

    end

    describe "with :environment_variable and type :flag" do

      before do
        command.class.option "--[no-]enable", :flag, "enable?", :default => false, :environment_variable => "ENABLE"
      end

      context "when no environment variable is present" do

        before do
          ENV.delete("ENABLE")
        end

        it "uses the default" do
          command.parse([])
          command.enable?.should == false
        end

      end

      %w(1 yes enable on true).each do |truthy_value|

        context "when environment variable is #{truthy_value.inspect}" do

          it "sets the flag" do
            ENV["ENABLE"] = truthy_value
            command.parse([])
            command.enable?.should == true
          end

        end

      end

      %w(0 no disable off false).each do |falsey_value|

        context "when environment variable is #{falsey_value.inspect}" do

          it "clears the flag" do
            ENV["ENABLE"] = falsey_value
            command.parse([])
            command.enable?.should == false
          end

        end

      end

    end

    describe "with :required" do

      before do
        command.class.option "--port", "PORT", "port to listen on", :required => true
      end

      context "when no value is provided" do

        it "raises a UsageError" do
          expect do
            command.parse([])
          end.to raise_error(Clamp::UsageError)
        end

      end

      context "when a value is provided" do

        it "does not raise an error" do
          expect do
            command.parse(["--port", "12345"])
          end.not_to raise_error
        end

      end

    end

    describe "with a block" do

      before do
        command.class.option "--port", "PORT", "Port to listen on" do |port|
          Integer(port)
        end
      end

      it "uses the block to validate and convert the option argument" do
        lambda do
          command.port = "blah"
        end.should raise_error(ArgumentError)
        command.port = "1234"
        command.port.should == 1234
      end

    end

  end

  describe "with options declared" do

    before do
      command.class.option ["-f", "--flavour"], "FLAVOUR", "Flavour of the month"
      command.class.option ["-c", "--color"], "COLOR", "Preferred hue"
      command.class.option ["--scoops"], "N", "Number of scoops",
          :default => 1,
          :environment_variable => "DEFAULT_SCOOPS" do |arg|
        Integer(arg)
      end
      command.class.option ["-n", "--[no-]nuts"], :flag, "Nuts (or not)\nMay include nuts"
      command.class.parameter "[ARG] ...", "extra arguments", :attribute_name => :arguments
    end

    describe "#parse" do

      describe "with an unrecognised option" do

        it "raises a UsageError" do
          lambda do
            command.parse(%w(--foo bar))
          end.should raise_error(Clamp::UsageError)
        end

      end

      describe "with options" do

        before do
          command.parse(%w(--flavour strawberry --nuts --color blue))
        end

        it "maps the option values onto the command object" do
          command.flavour.should == "strawberry"
          command.color.should == "blue"
          command.nuts?.should == true
        end

      end

      describe "with short options" do

        before do
          command.parse(%w(-f strawberry -c blue))
        end

        it "recognises short options as aliases" do
          command.flavour.should == "strawberry"
          command.color.should == "blue"
        end

      end

      describe "with a value appended to a short option" do

        before do
          command.parse(%w(-fstrawberry))
        end

        it "works as though the value were separated" do
          command.flavour.should == "strawberry"
        end

      end

      describe "with combined short options" do

        before do
          command.parse(%w(-nf strawberry))
        end

        it "works as though the options were separate" do
          command.flavour.should == "strawberry"
          command.nuts?.should == true
        end

      end

      describe "with option arguments attached using equals sign" do

        before do
          command.parse(%w(--flavour=strawberry --color=blue))
        end

        it "works as though the option arguments were separate" do
          command.flavour.should == "strawberry"
          command.color.should == "blue"
        end

      end

      describe "with option-like things beyond the arguments" do

        it "treats them as positional arguments" do
          command.parse(%w(a b c --flavour strawberry))
          command.arguments.should == %w(a b c --flavour strawberry)
        end

      end

      describe "with multi-line arguments that look like options" do

        before do
          command.parse(["foo\n--flavour=strawberry", "bar\n-cblue"])
        end

        it "treats them as positional arguments" do
          command.arguments.should == ["foo\n--flavour=strawberry", "bar\n-cblue"]
          command.flavour.should be_nil
          command.color.should be_nil
        end

      end

      describe "with an option terminator" do

        it "considers everything after the terminator to be an argument" do
          command.parse(%w(--color blue -- --flavour strawberry))
          command.arguments.should == %w(--flavour strawberry)
        end

      end

      describe "with --flag" do

        before do
          command.parse(%w(--nuts))
        end

        it "sets the flag" do
          command.nuts?.should be_true
        end

      end

      describe "with --no-flag" do

        before do
          command.nuts = true
          command.parse(%w(--no-nuts))
        end

        it "clears the flag" do
          command.nuts?.should be_false
        end

      end

      describe "with --help" do

        it "requests help" do
          lambda do
            command.parse(%w(--help))
          end.should raise_error(Clamp::HelpWanted)
        end

      end

      describe "with -h" do

        it "requests help" do
          lambda do
            command.parse(%w(-h))
          end.should raise_error(Clamp::HelpWanted)
        end

      end

      describe "when a bad option value is specified on the command-line" do

        it "signals a UsageError" do
          lambda do
            command.parse(%w(--scoops reginald))
          end.should raise_error(Clamp::UsageError, /^option '--scoops': invalid value for Integer/)
        end

      end

      describe "when a bad option value is specified in the environment" do

        it "signals a UsageError" do
          ENV["DEFAULT_SCOOPS"] = "marjorie"
          lambda do
            command.parse([])
          end.should raise_error(Clamp::UsageError, /^\$DEFAULT_SCOOPS: invalid value for Integer/)
        end

      end

    end

    describe "#help" do

      it "indicates that there are options" do
        command.help.should include("cmd [OPTIONS]")
      end

      it "includes option details" do
        command.help.should =~ %r(--flavour FLAVOUR +Flavour of the month)
        command.help.should =~ %r(--color COLOR +Preferred hue)
      end

      it "handles new lines in option descriptions" do
        command.help.should =~ %r(--\[no-\]nuts +Nuts \(or not\)\n +May include nuts)
      end

    end

  end

  describe "with an explicit --help option declared" do

    before do
      command.class.option ["--help"], :flag, "help wanted"
    end

    it "does not generate implicit help option" do
      lambda do
        command.parse(%w(--help))
      end.should_not raise_error
      command.help.should be_true
    end

    it "does not recognise -h" do
      lambda do
        command.parse(%w(-h))
      end.should raise_error(Clamp::UsageError)
    end

  end

  describe "with an explicit -h option declared" do

    before do
      command.class.option ["-h", "--humidity"], "PERCENT", "relative humidity" do |n|
        Integer(n)
      end
    end

    it "does not map -h to help" do
      command.help.should_not =~ %r( -h[, ].*help)
    end

    it "still recognises --help" do
      lambda do
        command.parse(%w(--help))
      end.should raise_error(Clamp::HelpWanted)
    end

  end

  describe ".parameter" do

    it "declares option argument accessors" do
      command.class.parameter "FLAVOUR", "flavour of the month"
      command.flavour.should == nil
      command.flavour = "chocolate"
      command.flavour.should == "chocolate"
    end

    describe "with explicit :attribute_name" do

      before do
        command.class.parameter "FOO", "a foo", :attribute_name => :bar
      end

      it "uses the specified attribute_name name to name accessors" do
        command.bar = "chocolate"
        command.bar.should == "chocolate"
      end

    end

    describe "with :default value" do

      before do
        command.class.parameter "[ORIENTATION]", "direction", :default => "west"
      end

      it "sets the specified default value" do
        command.orientation.should == "west"
      end

      describe "#help" do

        it "describes the default value" do
          command.help.should include("direction (default: \"west\")")
        end

      end

    end

    describe "with a block" do

      before do
        command.class.parameter "PORT", "port to listen on" do |port|
          Integer(port)
        end
      end

      it "uses the block to validate and convert the argument" do
        lambda do
          command.port = "blah"
        end.should raise_error(ArgumentError)
        command.port = "1234"
        command.port.should == 1234
      end

    end

    describe "with ellipsis" do

      before do
        command.class.parameter "FILE ...", "files"
      end

      it "accepts multiple arguments" do
        command.parse(%w(X Y Z))
        command.file_list.should == %w(X Y Z)
      end

    end

    describe "optional, with ellipsis" do

      before do
        command.class.parameter "[FILE] ...", "files"
      end

      it "default to an empty list" do
        command.parse([])
        command.default_file_list.should == []
        command.file_list.should == []
      end

    end

    describe "with :environment_variable value" do

      before do
        command.class.parameter "[FILE]", "a file", :environment_variable => "FILE",
          :default => "/dev/null"
      end

      it "should use the default if neither flag nor env var are present" do
        command.parse([])
        command.file.should == "/dev/null"
      end

      it "should use the env value if present (instead of default)" do
        ENV["FILE"] = "/etc/motd"
        command.parse([])
        command.file.should == ENV["FILE"]
      end

      it "should use the the flag value if present (instead of env)" do
        ENV["FILE"] = "/etc/motd"
        command.parse(%w(/bin/sh))
        command.file.should == "/bin/sh"
      end

      describe "#help" do

        it "describes the default value and env usage" do
          command.help.should include(%{ (default: $FILE, or "/dev/null")})
        end

      end

    end

  end

  describe "with no parameters declared" do

    describe "#parse" do

      describe "with arguments" do

        it "raises a UsageError" do
          lambda do
            command.parse(["crash"])
          end.should raise_error(Clamp::UsageError, "too many arguments")
        end

      end

    end

  end

  describe "with parameters declared" do

    before do
      command.class.parameter "X", "x\nxx"
      command.class.parameter "Y", "y"
      command.class.parameter "[Z]", "z", :default => "ZZZ"
    end

    describe "#parse" do

      describe "with arguments for all parameters" do

        before do
          command.parse(["crash", "bang", "wallop"])
        end

        it "maps arguments onto the command object" do
          command.x.should == "crash"
          command.y.should == "bang"
          command.z.should == "wallop"
        end

      end

      describe "with insufficient arguments" do

        it "raises a UsageError" do
          lambda do
            command.parse(["crash"])
          end.should raise_error(Clamp::UsageError, "parameter 'Y': no value provided")
        end

      end

      describe "with optional argument omitted" do

        it "defaults the optional argument" do
          command.parse(["crash", "bang"])
          command.x.should == "crash"
          command.y.should == "bang"
          command.z.should == "ZZZ"
        end

      end

      describe "with multi-line arguments" do

        it "parses them correctly" do
          command.parse(["foo\nhi", "bar", "baz"])
          command.x.should == "foo\nhi"
          command.y.should == "bar"
          command.z.should == "baz"
        end

      end

      describe "with too many arguments" do

        it "raises a UsageError" do
          lambda do
            command.parse(["crash", "bang", "wallop", "kapow"])
          end.should raise_error(Clamp::UsageError, "too many arguments")
        end

      end

    end

    describe "#help" do

      it "indicates that there are parameters" do
        command.help.should include("cmd [OPTIONS] X Y [Z]")
      end

      it "includes parameter details" do
        command.help.should =~ %r(X +x)
        command.help.should =~ %r(Y +y)
        command.help.should =~ %r(\[Z\] +z \(default: "ZZZ"\))
      end

      it "handles new lines in option descriptions" do
        command.help.should =~ %r(X +x\n +xx)
      end

    end


  end

  describe "with explicit usage" do

    given_command("blah") do

      usage "FOO BAR ..."

    end

    describe "#help" do

      it "includes the explicit usage" do
        command.help.should include("blah FOO BAR ...\n")
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
        command.help.should include("put THIS HERE\n")
        command.help.should include("put THAT THERE\n")
      end

    end

  end

  describe "with a banner" do

    given_command("punt") do

      banner <<-EOF
        Punt is an example command.  It doesn't do much, really.

        The prefix at the beginning of this description should be normalised
        to two spaces.
      EOF

    end

    describe "#help" do

      it "includes the banner" do
        command.help.should =~ /^  Punt is an example command/
        command.help.should =~ /^  The prefix/
      end

    end

  end

  describe ".run" do

    it "creates a new Command instance and runs it" do
      command.class.class_eval do
        parameter "WORD ...", "words"
        def execute
          print word_list.inspect
        end
      end
      @xyz = %w(x y z)
      command.class.run("cmd", @xyz)
      stdout.should == @xyz.inspect
    end

    describe "invoked with a context hash" do

      it "makes the context available within the command" do
        command.class.class_eval do
          def execute
            print context[:foo]
          end
        end
        command.class.run("xyz", [], :foo => "bar")
        stdout.should == "bar"
      end

    end

    describe "when there's a UsageError" do

      before do

        command.class.class_eval do
          def execute
            signal_usage_error "bad dog!"
          end
        end

        begin
          command.class.run("cmd", [])
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
        command.class.run("cmd", ["--help"])
        stdout.should include "Usage:"
      end

    end

  end

  describe "subclass" do

    let(:command) do
      parent_command_class = Class.new(Clamp::Command) do
        option "--verbose", :flag, "be louder"
      end
      derived_command_class = Class.new(parent_command_class) do
        option "--iterations", "N", "number of times to go around"
      end
      derived_command_class.new("cmd")
    end

    it "inherits options from it's superclass" do
      command.parse(["--verbose"])
      command.should be_verbose
    end

  end

end
