# frozen_string_literal: true

require "spec_helper"
require "clamp/completion"

describe Clamp::Completion do

  let(:command_class) do
    Class.new(Clamp::Command) do
      option ["-v", "--verbose"], :flag, "be verbose"
      option "--format", "FORMAT", "output format"
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

  describe "fish" do

    let(:script) { command_class.generate_completion(:fish, "myapp") }

    it "generates a non-empty string" do
      expect(script).to be_a(String)
      expect(script).not_to be_empty
    end

    it "includes top-level short and long switches" do
      expect(script).to include("-s v")
      expect(script).to include("-l verbose")
      expect(script).to include("-l format")
    end

    it "excludes hidden options" do
      expect(script).not_to include("secret")
    end

    it "includes help option" do
      expect(script).to include("-l help")
    end

    it "includes subcommand names" do
      expect(script).to match(/-a remote\b/)
      expect(script).to match(/-a status\b/)
    end

    it "includes subcommand aliases" do
      expect(script).to match(/-a rm\b/)
    end

    it "includes subcommand descriptions" do
      expect(script).to include("manage remotes")
      expect(script).to include("show status")
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
      require "tempfile"
      Tempfile.open(["completion", ".fish"]) do |f|
        f.write(script)
        f.flush
        ok = system("fish", "--no-execute", f.path, out: File::NULL, err: File::NULL)
        expect(ok).to be true
      end
    end

  end

end
