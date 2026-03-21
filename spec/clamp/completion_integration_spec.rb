# frozen_string_literal: true

require "spec_helper"
require "clamp/completion"
require "open3"
require "tempfile"

describe Clamp::Completion do

  let(:command_class) do
    Class.new(Clamp::Command) do
      option ["-v", "--verbose"], :flag, "be verbose"
      option ["-f", "--format"], "FORMAT", "output format"
      option "--[no-]color", :flag, "use color"
      option "--secret", :flag, "secret option", hidden: true

      subcommand "remote", "manage remotes" do
        subcommand "add", "add a remote" do
          option "--tracking", :flag, "set up tracking"
        end
        subcommand ["remove", "rm"], "remove a remote"
      end

      subcommand "status", "show status"

      subcommand ["deploy", "d"], "deploy stuff" do
        parameter "TARGET", "deploy target"
        subcommand "start", "start deploy"
        subcommand "rollback", "rollback deploy"
      end
    end
  end

  shared_examples "auto-completion script" do

    it "completes top-level options" do
      expect(complete("myapp --v")).to include("--verbose")
    end

    it "includes all top-level subcommands", :aggregate_failures do
      completions = complete("myapp ")
      expect(completions).to include("remote")
      expect(completions).to include("status")
    end

    it "completes nested subcommand options" do
      expect(complete("myapp remote add --t")).to include("--tracking")
    end

    it "completes inherited options in a subcommand" do
      expect(complete("myapp remote add --v")).to include("--verbose")
    end

    it "includes nested subcommands and aliases", :aggregate_failures do
      completions = complete("myapp remote ")
      expect(completions).to include("add")
      expect(completions).to include("rm")
    end

    it "suppresses completions after a valued option" do
      expect(complete("myapp --format ")).to be_empty
    end

    it "excludes hidden options" do
      expect(complete("myapp --s")).not_to include("--secret")
    end

    it "does not offer options without a dash prefix", :zsh_pending do
      expect(complete("myapp ")).not_to include("--verbose")
    end

    it "does not offer subcommands before required parameters are filled", :required_params do
      expect(complete("myapp deploy ")).not_to include("start")
    end

    it "does not offer subcommands before required parameters are filled, via alias", :required_params do
      expect(complete("myapp d ")).not_to include("start")
    end

    it "offers subcommands after required parameters are filled, via alias", :required_params do
      expect(complete("myapp d target ")).to include("start")
    end

    it "completes nested subcommand options via alias" do
      expect(complete("myapp remote rm --h")).to include("--help")
    end

    it "does not treat a long option value as a subcommand" do
      expect(complete("myapp --format yaml ")).to include("remote")
    end

    it "does not treat a long option=value as a subcommand", :compact_option_values do
      expect(complete("myapp --format=yaml ")).to include("remote")
    end

    it "does not treat a short option value as a subcommand" do
      expect(complete("myapp -f yaml ")).to include("remote")
    end

    it "does not treat a compact short option value as a subcommand", :compact_option_values do
      expect(complete("myapp -fyaml ")).to include("remote")
    end

  end

  describe "bash auto-completion script" do

    before do
      skip "bash not available" unless system("bash", "--version", out: File::NULL, err: File::NULL)
    end

    let(:script) { command_class.generate_completion(:bash, "myapp") }

    def complete(command_line)
      words = command_line.split(" ", -1)
      comp_words = words.map { |w| %("#{w}") }.join(" ")
      bash_script = <<~BASH
        #{script}
        COMP_WORDS=(#{comp_words})
        COMP_CWORD=#{words.length - 1}
        _clamp_complete_myapp
        printf '%s\\n' "${COMPREPLY[@]}"
      BASH
      stdout, status = Open3.capture2("bash", stdin_data: bash_script)
      raise "bash failed: #{status}" unless status.success?

      stdout.split("\n").reject(&:empty?)
    end

    it_behaves_like "auto-completion script"

  end

  describe "fish auto-completion script" do

    before do
      skip "fish not available" unless system("fish", "--version", out: File::NULL, err: File::NULL)
    end

    let(:script) { command_class.generate_completion(:fish, "myapp") }

    def complete(command_line)
      fish_script = <<~FISH
        #{script}
        complete --do-complete "#{command_line}"
      FISH
      stdout, status = Open3.capture2("fish", "--no-config", stdin_data: fish_script)
      raise "fish failed: #{status}" unless status.success?

      stdout.split("\n").map { |line| line.split("\t").first }.reject(&:empty?)
    end

    it_behaves_like "auto-completion script"

  end

  describe "zsh auto-completion script" do

    before do
      skip "zsh not available" unless system("zsh", "--version", out: File::NULL, err: File::NULL)
    end

    before(:example, :zsh_pending) do
      skip "zsh generator does not yet suppress options without dash prefix"
    end

    before(:example, :required_params) do
      skip "zsh generator does not yet handle required parameters before subcommands"
    end

    before(:example, :compact_option_values) do
      skip "zsh _arguments handles compact option values (--opt=val, -oval) internally"
    end

    let(:script) { command_class.generate_completion(:zsh, "myapp") }

    def complete(command_line)
      Tempfile.open(["completion", ".zsh"]) do |f|
        f.write(script)
        f.flush
        driver = File.expand_path("../support/zsh_complete.zsh", __dir__)
        stdout, status = Open3.capture2("zsh", driver, f.path, command_line)
        raise "zsh failed: #{status}" unless status.success?

        stdout.split("\n").reject(&:empty?).map { |line| line.split(" -- ").first }
      end
    end

    it_behaves_like "auto-completion script"

  end

end
