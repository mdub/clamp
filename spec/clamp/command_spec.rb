# frozen_string_literal: true

require "spec_helper"

describe Clamp::Command do

  extend CommandFactory
  include OutputCapture
  include SetEnv

  given_command("cmd") do

    def execute
      puts "Hello, world"
    end

  end

  describe "#help" do

    it "describes usage" do
      expect(command.help).to match(/^Usage:\n    cmd.*\n/)
    end

  end

  describe "#run" do

    before do
      command.run([])
    end

    it "executes the #execute method" do
      expect(stdout).not_to be_empty
    end

  end

  describe ".option" do

    context "when regular" do

      before do
        command.class.option "--flavour", "FLAVOUR", "Flavour of the month"
      end

      context "when not set" do
        it "equals nil" do
          expect(command.flavour).to be_nil
        end
      end

      context "when set" do
        before do
          command.flavour = "chocolate"
        end

        it "equals the value" do
          expect(command.flavour).to eq "chocolate"
        end
      end

    end

    context "with type :flag" do

      before do
        command.class.option "--verbose", :flag, "Be heartier"
      end

      describe "predicate-style reader" do

        it "exists" do
          expect(command).to respond_to(:verbose?)
        end

      end

      describe "regular reader" do

        it "does not exist" do
          expect(command).not_to respond_to(:verbose)
        end

      end

    end

    context "with explicit :attribute_name" do

      before do
        command.class.option "--foo", "FOO", "A foo", attribute_name: :bar
      end

      it "uses the specified attribute_name name to name accessors" do
        command.bar = "chocolate"
        expect(command.bar).to eq "chocolate"
      end

      describe "default reader" do
        it "does not exist" do
          expect(command).not_to respond_to(:foo)
        end
      end

      describe "default writer" do
        it "does not exist" do
          expect(command).not_to respond_to(:foo=)
        end
      end

    end

    context "with default method" do

      before do
        command.class.option "--port", "PORT", "port"
        command.class.class_eval do
          def default_port
            4321
          end
        end
      end

      it "sets the specified default value" do
        expect(command.port).to eq 4321
      end

    end

    context "with :default value" do

      before do
        command.class.option "--port", "PORT", "port to listen on", default: 4321
      end

      it "declares default method" do
        expect(command.default_port).to eq 4321
      end

      describe "#help" do

        it "describes the default value" do
          expect(command.help).to include("port to listen on (default: 4321)")
        end

      end

    end

    context "without :default value" do

      before do
        command.class.option "--port", "PORT", "port to listen on"
      end

      it "does not declare default method" do
        expect(command).not_to respond_to(:default_port)
      end

    end

    context "with :multivalued" do

      before do
        command.class.option "--flavour", "FLAVOUR", "flavour(s)", multivalued: true, attribute_name: :flavours
      end

      it "defaults to empty array" do
        expect(command.flavours).to be_empty
      end

      it "supports multiple values" do
        command.parse(%w[--flavour chocolate --flavour vanilla])
        expect(command.flavours).to eq %w[chocolate vanilla]
      end

      it "generates a single-value appender method" do
        command.append_to_flavours("mud")
        command.append_to_flavours("pie")
        expect(command.flavours).to eq %w[mud pie]
      end

      it "generates a multi-value setter method" do
        command.append_to_flavours("replaceme")
        command.flavours = %w[mud pie]
        expect(command.flavours).to eq %w[mud pie]
      end

      it "does not require a value" do
        expect do
          command.parse([])
        end.not_to raise_error
      end

    end

    context "with :environment_variable" do

      let(:environment_value) { nil }
      let(:args) { [] }

      before do
        command.class.option "--port", "PORT", "port to listen on",
                             default: 4321,
                             environment_variable: "PORT",
                             &:to_i
        set_env("PORT", environment_value)
        command.parse(args)
      end

      context "when no environment variable is present" do

        it "uses the default" do
          expect(command.port).to eq 4321
        end

      end

      context "when environment variable is present" do

        let(:environment_value) { "12345" }

        it "uses the environment variable" do
          expect(command.port).to eq 12_345
        end

        context "when a value is specified on the command-line" do

          let(:args) { %w[--port 1500] }

          it "uses command-line value" do
            expect(command.port).to eq 1500
          end

        end

      end

      describe "#help" do

        it "describes the default value and env usage" do
          expect(command.help).to include("port to listen on (default: $PORT, or 4321)")
        end

      end

    end

    context "with :environment_variable and type :flag" do

      let(:environment_value) { nil }

      before do
        command.class.option "--[no-]enable", :flag, "enable?", default: false, environment_variable: "ENABLE"
        set_env("ENABLE", environment_value)
        command.parse([])
      end

      context "when no environment variable is present" do

        it "uses the default" do
          expect(command.enable?).to be false
        end

      end

      %w[1 yes enable on true].each do |truthy_value|

        context "when environment variable is #{truthy_value.inspect}" do

          let(:environment_value) { truthy_value }

          it "sets the flag" do
            expect(command.enable?).to be true
          end

        end

      end

      %w[0 no disable off false].each do |falsey_value|

        context "when environment variable is #{falsey_value.inspect}" do

          let(:environment_value) { falsey_value }

          it "clears the flag" do
            expect(command.enable?).to be false
          end

        end

      end

    end

    context "with :required" do

      before do
        command.class.option "--port", "PORT", "port to listen on", required: true
      end

      describe "#help" do

        it "marks it as required" do
          expect(command.help).to include("port to listen on (required)")
        end

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

    context "with :required and :multivalued" do

      before do
        command.class.option "--port", "PORT", "port to listen on", required: true, multivalued: true
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

    context "with a block" do

      before do
        command.class.option "--port", "PORT", "Port to listen on" do |port|
          Integer(port)
        end
      end

      context "when value is incorrect" do

        it "raises an error" do
          expect do
            command.port = "blah"
          end.to raise_error(ArgumentError)
        end

      end

      context "when value is convertible" do

        it "uses the block to validate and convert the option argument" do
          command.port = "1234"
          expect(command.port).to eq 1234
        end

      end

    end

  end

  context "with options declared" do

    before do
      command.class.option ["-f", "--flavour"], "FLAVOUR", "Flavour of the month"
      command.class.option ["-c", "--color"], "COLOR", "Preferred hue"
      command.class.option ["--scoops"], "N", "Number of scoops",
                           default: 1,
                           environment_variable: "DEFAULT_SCOOPS" do |arg|
        Integer(arg)
      end
      command.class.option ["-n", "--[no-]nuts"], :flag, "Nuts (or not)\nMay include nuts"
      command.class.parameter "[ARG] ...", "extra arguments", attribute_name: :arguments
    end

    describe "#parse" do

      context "with an unrecognised option" do

        it "raises a UsageError" do
          expect do
            command.parse(%w[--foo bar])
          end.to raise_error(Clamp::UsageError)
        end

      end

      context "with options" do

        before do
          command.parse(%w[--flavour strawberry --nuts --color blue])
        end

        describe "flavour" do
          it "maps the option value onto the command object" do
            expect(command.flavour).to eq "strawberry"
          end
        end

        describe "color" do
          it "maps the option value onto the command object" do
            expect(command.color).to eq "blue"
          end
        end

        describe "nuts?" do
          it "maps the option value onto the command object" do
            expect(command.nuts?).to be true
          end
        end

      end

      context "with short options" do

        before do
          command.parse(%w[-f strawberry -c blue])
        end

        describe "flavour" do
          it "recognizes short options as aliases" do
            expect(command.flavour).to eq "strawberry"
          end
        end

        describe "color" do
          it "recognizes short options as aliases" do
            expect(command.color).to eq "blue"
          end
        end

      end

      context "with a value appended to a short option" do

        before do
          command.parse(%w[-fstrawberry])
        end

        it "works as though the value were separated" do
          expect(command.flavour).to eq "strawberry"
        end

      end

      context "with combined short options" do

        before do
          command.parse(%w[-nf strawberry])
        end

        describe "flavour" do
          it "works as though the options were separate" do
            expect(command.flavour).to eq "strawberry"
          end
        end

        describe "nuts?" do
          it "works as though the options were separate" do
            expect(command.nuts?).to be true
          end
        end

      end

      context "with option arguments attached using equals sign" do

        before do
          command.parse(%w[--flavour=strawberry --color=blue])
        end

        describe "flavour" do
          it "maps the option value onto the command object" do
            expect(command.flavour).to eq "strawberry"
          end
        end

        describe "color" do
          it "maps the option value onto the command object" do
            expect(command.color).to eq "blue"
          end
        end

      end

      context "with option arguments that look like options" do

        before do
          command.parse(%w[--flavour=-dashing- --scoops -1])
        end

        describe "flavour" do
          it "sets the options" do
            expect(command.flavour).to eq("-dashing-")
          end
        end

        describe "scoops" do
          it "sets the options" do
            expect(command.scoops).to eq(-1)
          end
        end

      end

      context "with option-like things beyond the arguments" do

        it "treats them as positional arguments" do
          command.parse(%w[a b c --flavour strawberry])
          expect(command.arguments).to eq %w[a b c --flavour strawberry]
        end

      end

      context "with multi-line arguments that look like options" do

        before do
          command.parse(["foo\n--flavour=strawberry", "bar\n-cblue"])
        end

        describe "arguments" do
          it "treats them as positional arguments" do
            expect(command.arguments).to eq ["foo\n--flavour=strawberry", "bar\n-cblue"]
          end
        end

        describe "flavour" do
          it "treats them as positional arguments" do
            expect(command.flavour).to be_nil
          end
        end

        describe "color" do
          it "treats them as positional arguments" do
            expect(command.color).to be_nil
          end
        end

      end

      context "with an option terminator" do

        it "considers everything after the terminator to be an argument" do
          command.parse(%w[--color blue -- --flavour strawberry])
          expect(command.arguments).to eq %w[--flavour strawberry]
        end

      end

      context "with --flag" do

        before do
          command.parse(%w[--nuts])
        end

        it "sets the flag" do
          expect(command.nuts?).to be true
        end

      end

      context "with --no-flag" do

        before do
          command.nuts = true
          command.parse(%w[--no-nuts])
        end

        it "clears the flag" do
          expect(command.nuts?).to be false
        end

      end

      context "with --help" do

        it "requests help" do
          expect do
            command.parse(%w[--help])
          end.to raise_error(Clamp::HelpWanted)
        end

      end

      context "with -h" do

        it "requests help" do
          expect do
            command.parse(%w[-h])
          end.to raise_error(Clamp::HelpWanted)
        end

      end

      context "when a bad option value is specified on the command-line" do

        it "signals a UsageError" do
          expect do
            command.parse(%w[--scoops reginald])
          end.to raise_error(Clamp::UsageError, /^option '--scoops': invalid value for Integer/)
        end

      end

      context "when a bad option value is specified in the environment" do

        it "signals a UsageError" do
          ENV["DEFAULT_SCOOPS"] = "marjorie"
          expect do
            command.parse([])
          end.to raise_error(Clamp::UsageError, /^\$DEFAULT_SCOOPS: invalid value for Integer/)
        end

      end

    end

    describe "#help" do

      it "indicates that there are options" do
        expect(command.help).to include("cmd [OPTIONS]")
      end

      it "includes option details" do
        flavour_help = "-f, --flavour FLAVOUR +Flavour of the month"
        color_help = "-c, --color COLOR +Preferred hue"

        expect(command.help).to match(/#{flavour_help}\n +#{color_help}/)
      end

      it "handles new lines in option descriptions" do
        expect(command.help).to match(/--\[no-\]nuts +Nuts \(or not\)\n +May include nuts/)
      end

    end

  end

  context "with an explicit --help option declared" do

    before do
      command.class.option ["--help"], :flag, "help wanted"
    end

    describe "parsing" do
      it "does not generate implicit help option" do
        expect do
          command.parse(%w[--help])
        end.not_to raise_error
      end
    end

    describe "help?" do
      before do
        command.parse(%w[--help])
      end

      it "generates custom help option" do
        expect(command.help?).to be true
      end
    end

    it "does not recognise -h" do
      expect do
        command.parse(%w[-h])
      end.to raise_error(Clamp::UsageError)
    end

  end

  context "with an explicit -h option declared" do

    before do
      command.class.option ["-h", "--humidity"], "PERCENT", "relative humidity" do |n|
        Integer(n)
      end
    end

    it "does not map -h to help" do
      expect(command.help).not_to match(/-h[, ].*help/)
    end

    it "still recognizes --help" do
      expect do
        command.parse(%w[--help])
      end.to raise_error(Clamp::HelpWanted)
    end

  end

  describe ".parameter" do

    context "when regular" do

      before do
        command.class.parameter "FLAVOUR", "flavour of the month"
      end

      context "when not set" do
        it "equals nil" do
          expect(command.flavour).to be_nil
        end
      end

      context "when set" do
        before do
          command.flavour = "chocolate"
        end

        it "equals the value" do
          expect(command.flavour).to eq "chocolate"
        end
      end

    end

    context "with explicit :attribute_name" do

      before do
        command.class.parameter "FOO", "a foo", attribute_name: :bar
      end

      it "uses the specified attribute_name name to name accessors" do
        command.bar = "chocolate"
        expect(command.bar).to eq "chocolate"
      end

    end

    context "with :default value" do

      before do
        command.class.parameter "[ORIENTATION]", "direction", default: "west"
      end

      it "sets the specified default value" do
        expect(command.orientation).to eq "west"
      end

      describe "#help" do

        it "describes the default value" do
          expect(command.help).to include("direction (default: \"west\")")
        end

      end

    end

    context "with a block" do

      before do
        command.class.parameter "PORT", "port to listen on" do |port|
          Integer(port)
        end
      end

      context "when value is incorrect" do

        it "raises an error" do
          expect do
            command.port = "blah"
          end.to raise_error(ArgumentError)
        end

      end

      context "when value is convertible" do

        it "uses the block to validate and convert the argument" do
          command.port = "1234"
          expect(command.port).to eq 1234
        end

      end

    end

    context "with ellipsis" do

      before do
        command.class.parameter "FILE ...", "files"
      end

      it "accepts multiple arguments" do
        command.parse(%w[X Y Z])
        expect(command.file_list).to eq %w[X Y Z]
      end

    end

    context "when optional, with ellipsis" do

      before do
        command.class.parameter "[FILE] ...", "files"

        command.parse([])
      end

      describe "default_file_list" do

        it "defaults to an empty list" do
          expect(command.default_file_list).to be_empty
        end

      end

      describe "file_list" do

        it "defaults to an empty list" do
          expect(command.file_list).to be_empty
        end

      end

      describe "mutation" do

        before do
          command.file_list << "treasure"
        end

        it "is mutable" do
          expect(command.file_list).to eq ["treasure"]
        end

      end

    end

    context "with :environment_variable" do

      before do
        command.class.parameter "[FILE]", "a file", environment_variable: "FILE",
                                                    default: "/dev/null"

        set_env("FILE", environment_value)
        command.parse(args)
      end

      let(:args) { [] }
      let(:environment_value) { nil }

      context "when neither argument nor environment variable are present" do

        it "uses the default" do
          expect(command.file).to eq "/dev/null"
        end

      end

      context "when environment variable is present" do

        let(:environment_value) { "/etc/motd" }

        describe "and no argument is provided" do

          it "uses the environment variable" do
            expect(command.file).to eq "/etc/motd"
          end

        end

        describe "and an argument is provided" do

          let(:args) { ["/dev/null"] }

          it "uses the argument" do
            expect(command.file).to eq "/dev/null"
          end

        end

      end

      describe "#help" do

        it "describes the default value and env usage" do
          expect(command.help).to include(%{ (default: $FILE, or "/dev/null")})
        end

      end

    end

  end

  context "with no parameters declared" do

    describe "#parse" do

      context "with arguments" do

        it "raises a UsageError" do
          expect do
            command.parse(["crash"])
          end.to raise_error(Clamp::UsageError, "too many arguments")
        end

      end

    end

  end

  context "with parameters declared" do

    before do
      command.class.parameter "X", "x\nxx"
      command.class.parameter "Y", "y"
      command.class.parameter "[Z]", "z", default: "ZZZ"
    end

    describe "#parse" do

      context "with arguments for all parameters" do

        before do
          command.parse(["crash", "bang", "wallop"])
        end

        describe "x" do
          it "maps arguments onto the command object" do
            expect(command.x).to eq "crash"
          end
        end

        describe "y" do
          it "maps arguments onto the command object" do
            expect(command.y).to eq "bang"
          end
        end

        describe "z" do
          it "maps arguments onto the command object" do
            expect(command.z).to eq "wallop"
          end
        end

      end

      context "with insufficient arguments" do

        it "raises a UsageError" do
          expect do
            command.parse(["crash"])
          end.to raise_error(Clamp::UsageError, "parameter 'Y': no value provided")
        end

      end

      context "with optional argument omitted" do

        before do
          command.parse(["crash", "bang"])
        end

        describe "x" do
          it "defaults the optional argument" do
            expect(command.x).to eq "crash"
          end
        end

        describe "y" do
          it "defaults the optional argument" do
            expect(command.y).to eq "bang"
          end
        end

        describe "z" do
          it "defaults the optional argument" do
            expect(command.z).to eq "ZZZ"
          end
        end

      end

      context "with multi-line arguments" do

        before do
          command.parse(["foo\nhi", "bar", "baz"])
        end

        describe "x" do
          it "parses them correctly" do
            expect(command.x).to eq "foo\nhi"
          end
        end

        describe "y" do
          it "parses them correctly" do
            expect(command.y).to eq "bar"
          end
        end

        describe "z" do
          it "parses them correctly" do
            expect(command.z).to eq "baz"
          end
        end

      end

      context "with too many arguments" do

        it "raises a UsageError" do
          expect do
            command.parse(["crash", "bang", "wallop", "kapow"])
          end.to raise_error(Clamp::UsageError, "too many arguments")
        end

      end

    end

    describe "#help" do

      it "indicates that there are parameters" do
        expect(command.help).to include("cmd [OPTIONS] X Y [Z]")
      end

      it "includes parameter details" do
        expect(command.help).to match(/X +x\n[\s\S]* +Y +y\n[\s\S]* +\[Z\] +z \(default: "ZZZ"\)/)
      end

      it "handles new lines in option descriptions" do
        expect(command.help).to match(/X +x\n +xx/)
      end

    end

  end

  describe ".execute" do

    before do

      command_class.class_eval do
        execute do
          puts "using execute DSL"
        end
      end

      command.run([])

    end

    it "provides an alternative way to declare execute method" do
      expect(stdout).to eq("using execute DSL\n")
    end

  end

  context "with explicit usage" do

    given_command("blah") do

      usage "FOO BAR ..."

    end

    describe "#help" do

      it "includes the explicit usage" do
        expect(command.help).to include("blah FOO BAR ...\n")
      end

    end

  end

  context "with multiple usages" do

    given_command("put") do

      usage "THIS HERE"
      usage "THAT THERE"

    end

    describe "#help" do

      it "includes both potential usages" do
        expect(command.help).to match(/put THIS HERE\n +put THAT THERE/)
      end

    end

  end

  context "with a banner" do

    given_command("punt") do

      banner <<-TEXT
        Punt is an example command.  It doesn't do much, really.

        The prefix at the beginning of this description should be normalised
        to two spaces.
      TEXT

    end

    describe "#help" do

      it "includes the banner" do
        expect(command.help).to match(/^  Punt is an example command.+\n^  \n^  The prefix/)
      end

    end

  end

  describe ".run" do

    context "when regular" do

      before do

        command.class.class_eval do
          parameter "WORD ...", "words"
          def execute
            print word_list.inspect
          end
        end

      end

      it "creates a new Command instance and runs it" do
        xyz = %w[x y z]
        command.class.run("cmd", xyz)
        expect(stdout).to eq xyz.inspect
      end

    end

    context "when invoked with a context hash" do

      before do

        command.class.class_eval do
          def execute
            print context[:foo]
          end
        end

      end

      it "makes the context available within the command" do
        command.class.run("xyz", [], foo: "bar")
        expect(stdout).to eq "bar"
      end

    end

    context "when there's a CommandError" do

      before do

        command.class.class_eval do
          def execute
            signal_error "Oh crap!", status: 456
          end
        end

      end

      it "outputs the error message and exits with the specified status" do
        expect { command.class.run("cmd", []) }
          .to raise_error(
            an_instance_of(SystemExit).and(having_attributes(status: 456))
          ).and output(<<~TEXT).to_stderr
            ERROR: Oh crap!
          TEXT
      end

    end

    context "when there's a UsageError" do

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

      it "outputs the error message and help" do
        expect { command.class.run("cmd", []) }
          .to raise_error(
            an_instance_of(SystemExit).and(having_attributes(status: 1))
          ).and output(<<~TEXT).to_stderr
            ERROR: bad dog!

            See: 'cmd --help'
          TEXT
      end

    end

    context "when help is requested" do

      it "outputs help" do
        command.class.run("cmd", ["--help"])
        expect(stdout).to include "Usage:"
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
      expect(command).to be_verbose
    end

  end

end
