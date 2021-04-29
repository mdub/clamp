# frozen_string_literal: true

require "spec_helper"

describe Clamp::Option::Definition do

  context "with String argument" do

    let(:option) do
      described_class.new("--key-file", "FILE", "SSH identity")
    end

    it "has a long_switch" do
      expect(option.long_switch).to eq "--key-file"
    end

    it "has a type" do
      expect(option.type).to eq "FILE"
    end

    it "has a description" do
      expect(option.description).to eq "SSH identity"
    end

    describe "#attribute_name" do

      it "is derived from the (long) switch" do
        expect(option.attribute_name).to eq "key_file"
      end

      it "can be overridden" do
        option = described_class.new("--key-file", "FILE", "SSH identity", attribute_name: "ssh_identity")
        expect(option.attribute_name).to eq "ssh_identity"
      end

    end

    describe "#write_method" do

      it "is derived from the attribute_name" do
        expect(option.write_method).to eq "key_file="
      end

    end

    describe "#default_value" do

      it "defaults to nil" do
        option = described_class.new("-n", "N", "iterations")
        expect(option.default_value).to be_nil
      end

      it "can be overridden" do
        option = described_class.new("-n", "N", "iterations", default: 1)
        expect(option.default_value).to eq 1
      end

    end

    describe "#help" do

      it "combines switch, type and description" do
        expect(option.help).to eq ["--key-file FILE", "SSH identity"]
      end

    end

  end

  context "when flag" do

    let(:option) do
      described_class.new("--verbose", :flag, "Blah blah blah")
    end

    describe "#default_conversion_block" do

      context "with 'true' value" do
        it "converts to true" do
          expect(option.default_conversion_block.call("true")).to be true
        end
      end

      context "with 'yes' value" do
        it "converts to true" do
          expect(option.default_conversion_block.call("yes")).to be true
        end
      end

      context "with 'false' value" do
        it "converts to false" do
          expect(option.default_conversion_block.call("false")).to be false
        end
      end

      context "with 'no' value" do
        it "converts to false" do
          expect(option.default_conversion_block.call("no")).to be false
        end
      end

    end

    describe "#help" do

      it "excludes option argument" do
        expect(option.help).to eq ["--verbose", "Blah blah blah"]
      end

    end

  end

  context "when negatable flag" do

    let(:option) do
      described_class.new("--[no-]force", :flag, "Force installation")
    end

    describe "positive form" do
      it "handles this" do
        expect(option.handles?("--force")).to be true
      end
    end

    describe "negative form" do
      it "handles this" do
        expect(option.handles?("--no-force")).to be true
      end
    end

    describe "#flag_value" do

      describe "positive variant" do
        it "returns true" do
          expect(option.flag_value("--force")).to be true
        end
      end

      describe "negative variant" do
        it "returns false" do
          expect(option.flag_value("--no-force")).to be false
        end
      end

    end

    describe "#attribute_name" do

      it "is derived from the (long) switch" do
        expect(option.attribute_name).to eq "force"
      end

    end

  end

  context "with both short and long switches" do

    let(:option) do
      described_class.new(["-k", "--key-file"], "FILE", "SSH identity")
    end

    describe "long switch" do
      it "handles this" do
        expect(option.handles?("--key-file")).to be true
      end
    end

    describe "short switch" do
      it "handles this" do
        expect(option.handles?("-k")).to be true
      end
    end

    describe "#help" do

      it "includes both switches" do
        expect(option.help).to eq ["-k, --key-file FILE", "SSH identity"]
      end

    end

  end

  context "with an associated environment variable" do

    let(:option) do
      described_class.new("-x", "X", "mystery option", environment_variable: "APP_X")
    end

    describe "#help" do

      it "describes environment variable" do
        expect(option.help).to eq ["-x X", "mystery option (default: $APP_X)"]
      end

    end

    context "with a default value" do

      let(:option) do
        described_class.new("-x", "X", "mystery option", environment_variable: "APP_X", default: "xyz")
      end

      describe "#help" do

        it "describes both environment variable and default" do
          expect(option.help).to eq ["-x X", %{mystery option (default: $APP_X, or "xyz")}]
        end

      end

    end

    context "and is required" do

      let(:option) do
        described_class.new("-x", "X", "mystery option", environment_variable: "APP_X", required: true)
      end

      describe "#help" do

        it "describes the environment variable as the default" do
          expect(option.help).to eql ["-x X", %{mystery option (required, default: $APP_X)}]
        end

      end

    end

  end

  context "when multivalued" do

    let(:option) do
      described_class.new(["-H", "--header"], "HEADER", "extra header", multivalued: true)
    end

    it "is multivalued" do
      expect(option).to be_multivalued
    end

    describe "#default_value" do

      it "defaults to an empty Array" do
        expect(option.default_value).to be_empty
      end

      it "can be overridden" do
        option = described_class.new("-H", "HEADER", "extra header", multivalued: true, default: [1, 2, 3])
        expect(option.default_value).to eq [1, 2, 3]
      end

    end

    describe "#attribute_name" do

      it "gets a _list suffix" do
        expect(option.attribute_name).to eq "header_list"
      end

    end

    describe "#append_method" do

      it "is derived from the attribute_name" do
        expect(option.append_method).to eq "append_to_header_list"
      end

    end

  end

  describe "in subcommand" do

    let(:command_class) do

      Class.new(Clamp::Command) do
        subcommand "foo", "FOO!" do
          option "--bar", "BAR", "Bars foo."
        end
      end

    end

    describe "Command#help" do

      it "includes help for each option exactly once" do
        subcommand = command_class.send(:find_subcommand, "foo")
        subcommand_help = subcommand.subcommand_class.help("")
        expect(subcommand_help.lines.grep(/--bar BAR/).count).to eq 1
      end

    end

  end

  describe "a required option" do
    it "rejects :default" do
      expect do
        described_class.new("--key-file", "FILE", "SSH identity",
                            required: true, default: "hello")
      end.to raise_error(ArgumentError)
    end

    it "rejects :flag options" do
      expect do
        described_class.new("--awesome", :flag, "Be awesome?", required: true)
      end.to raise_error(ArgumentError)
    end
  end

  describe "a hidden option" do
    let(:option) { described_class.new("--unseen", :flag, "Something", hidden: true) }

    it "is hidden" do
      expect(option).to be_hidden
    end
  end

  describe "a hidden option in a command" do
    let(:command_class) do
      Class.new(Clamp::Command) do
        option "--unseen", :flag, "Something", hidden: true

        def execute
          # this space intentionally left blank
        end
      end
    end

    it "is not shown in the help" do
      expect(command_class.help("foo")).not_to match(/^ +--unseen +Something$/)
    end

    it "sets the expected accessor" do
      command = command_class.new("foo")
      command.run(["--unseen"])
      expect(command).to be_unseen
    end
  end
end
