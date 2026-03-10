# frozen_string_literal: true

require "spec_helper"
require "clamp/completion"
require "tempfile"

RSpec::Matchers.define :be_valid_fish_syntax do
  match do |script|
    Tempfile.open(["completion", ".fish"]) do |f|
      f.write(script)
      f.flush
      system("fish", "--no-execute", f.path, out: File::NULL, err: File::NULL)
    end
  end
end

RSpec::Matchers.define :be_valid_zsh_syntax do
  match do |script|
    Tempfile.open(["completion", ".zsh"]) do |f|
      f.write(script)
      f.flush
      system("zsh", "-n", f.path, out: File::NULL, err: File::NULL)
    end
  end
end

RSpec::Matchers.define :be_valid_bash_syntax do
  match do |script|
    Tempfile.open(["completion", ".bash"]) do |f|
      f.write(script)
      f.flush
      system("bash", "-n", f.path, out: File::NULL, err: File::NULL)
    end
  end
end

describe Clamp::Completion do

  let(:command_class) do
    Class.new(Clamp::Command) do
      option ["-v", "--verbose"], :flag, "be verbose"
      option "--format", "FORMAT", "output format"
      option "--[no-]color", :flag, "use color"
      option "--secret", :flag, "secret option", hidden: true

      subcommand "remote", "manage remotes" do
        subcommand "add", "add a remote" do
          option "--tracking", :flag, "set up tracking"
        end
        subcommand ["remove", "rm"], "remove a remote"
      end

      subcommand "status", "show status"
    end
  end

  describe ".generate_completion" do

    it "raises for unsupported shells" do
      expect { command_class.generate_completion(:powershell, "myapp") }
        .to raise_error(ArgumentError, /unsupported shell/)
    end

  end

  describe "--shell-completions option" do

    include OutputCapture

    let(:simple_command) do
      Class.new(Clamp::Command) do
        option ["-v", "--verbose"], :flag, "be verbose"
        parameter "FILE", "input file"
        def execute; end
      end
    end

    it "generates completions for a command without subcommands" do
      simple_command.run("myapp", ["--shell-completions", "fish"])
      expect(stdout).to include("complete -c myapp")
    end

    it "includes the command's options" do
      simple_command.run("myapp", ["--shell-completions", "fish"])
      expect(stdout).to include("-l verbose")
    end

    it "accepts a full shell path" do
      simple_command.run("myapp", ["--shell-completions", "/usr/bin/fish"])
      expect(stdout).to include("complete -c myapp")
    end

    it "is hidden from help output" do
      expect(simple_command.help("myapp")).not_to include("--shell-completions")
    end

    it "does not include itself in generated completions" do
      simple_command.run("myapp", ["--shell-completions", "fish"])
      expect(stdout).not_to include("--shell-completions")
    end

    it "exits for unsupported shells" do
      expect { simple_command.run("myapp", ["--shell-completions", "powershell"]) }
        .to raise_error(SystemExit)
    end

    it "reports unsupported shells to stderr" do
      simple_command.run("myapp", ["--shell-completions", "powershell"])
    rescue SystemExit # rubocop:disable Lint/SuppressedException
    ensure
      expect(stderr).to include("unsupported shell")
    end

  end

  describe "bash" do

    let(:script) { command_class.generate_completion(:bash, "myapp") }

    it "returns a string" do
      expect(script).to be_a(String)
    end

    it "includes long option switches" do
      expect(script).to include("--verbose")
    end

    it "includes valued option switches" do
      expect(script).to include("--format")
    end

    it "includes short switches" do
      expect(script).to include("-v")
    end

    it "expands --[no-] options to positive form" do
      expect(script).to include("--color")
    end

    it "expands --[no-] options to negative form" do
      expect(script).to include("--no-color")
    end

    it "excludes hidden options" do
      expect(script).not_to include("secret")
    end

    it "includes help option" do
      expect(script).to include("--help")
    end

    it "includes subcommand names" do
      expect(script).to include("remote")
    end

    it "includes other subcommand names" do
      expect(script).to include("status")
    end

    it "includes subcommand aliases" do
      expect(script).to include("rm")
    end

    it "includes nested subcommand options" do
      expect(script).to include("--tracking")
    end

    it "registers the completion function" do
      expect(script).to include("complete -F _myapp myapp")
    end

    it "lists valued options in takes_value function" do
      expect(script).to include("--format) return 0")
    end

    it "excludes flags from takes_value function" do
      expect(script).not_to include("--verbose) return 0")
    end

    it "passes bash syntax validation" do
      skip "bash not available" unless system("bash", "--version", out: File::NULL, err: File::NULL)
      expect(script).to be_valid_bash_syntax
    end

  end

  describe "zsh" do

    let(:script) { command_class.generate_completion(:zsh, "myapp") }

    it "returns a string" do
      expect(script).to be_a(String)
    end

    it "includes compdef header" do
      expect(script).to include("#compdef myapp")
    end

    it "includes option specs with mutual exclusion" do
      expect(script).to include("(-v --verbose)")
    end

    it "includes brace expansion for short and long switches" do
      expect(script).to include("{-v,--verbose}")
    end

    it "includes option descriptions" do
      expect(script).to include("[be verbose]")
    end

    it "marks valued options as requiring an argument" do
      expect(script).to match(/--format\[output format\]:/)
    end

    it "expands --[no-] options to positive form" do
      expect(script).to include("--color")
    end

    it "expands --[no-] options to negative form" do
      expect(script).to include("--no-color")
    end

    it "excludes hidden options" do
      expect(script).not_to include("secret")
    end

    it "includes help option" do
      expect(script).to include("--help")
    end

    it "includes subcommand names with descriptions" do
      expect(script).to include("remote:manage remotes")
    end

    it "includes subcommand aliases" do
      expect(script).to include("rm:remove a remote")
    end

    it "generates per-subcommand functions" do
      expect(script).to include("_myapp_remote()")
    end

    it "generates nested subcommand functions" do
      expect(script).to include("_myapp_remote_add()")
    end

    it "includes nested subcommand options" do
      expect(script).to include("[set up tracking]")
    end

    it "uses _describe for subcommand listing" do
      expect(script).to include("_describe")
    end

    it "passes zsh syntax validation" do
      skip "zsh not available" unless system("zsh", "--version", out: File::NULL, err: File::NULL)
      expect(script).to be_valid_zsh_syntax
    end

  end

  describe "fish" do

    let(:script) { command_class.generate_completion(:fish, "myapp") }

    it "returns a string" do
      expect(script).to be_a(String)
    end

    it "includes short switches" do
      expect(script).to include("-s v")
    end

    it "includes long switches" do
      expect(script).to include("-l verbose")
    end

    it "includes valued option switches" do
      expect(script).to include("-l format")
    end

    it "expands --[no-] options to positive form" do
      expect(script).to include("-l color")
    end

    it "expands --[no-] options to negative form" do
      expect(script).to include("-l no-color")
    end

    it "excludes --shell-completions from completions" do
      expect(script).not_to match(/^complete\b.*shell-completions/)
    end

    it "includes help option" do
      expect(script).to include("-l help")
    end

    it "includes subcommand names" do
      expect(script).to match(/-a remote\b/)
    end

    it "includes other subcommand names" do
      expect(script).to match(/-a status\b/)
    end

    it "includes subcommand aliases" do
      expect(script).to match(/-a rm\b/)
    end

    it "includes subcommand descriptions" do
      expect(script).to include("manage remotes")
    end

    it "includes nested subcommand options" do
      expect(script).to include("-l tracking")
    end

    it "marks valued options as requiring an argument" do
      format_line = script.lines.find { |l| l.include?("-l format") }
      expect(format_line).to include("-r")
    end

    it "does not mark flag options as requiring an argument" do
      verbose_line = script.lines.find { |l| l.include?("-l verbose") }
      expect(verbose_line).not_to include("-r")
    end

    it "passes fish syntax validation" do
      skip "fish not available" unless system("fish", "--version", out: File::NULL, err: File::NULL)
      expect(script).to be_valid_fish_syntax
    end

  end

end
