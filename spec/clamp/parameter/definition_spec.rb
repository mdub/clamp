require 'spec_helper'

describe Clamp::Parameter::Definition do

  describe "normal" do

    let(:parameter) do
      described_class.new("COLOR", "hue of choice")
    end

    it "has a name" do
      parameter.name.should == "COLOR"
    end

    it "has a description" do
      parameter.description.should == "hue of choice"
    end

    it "is single-valued" do
      parameter.should_not be_multivalued
    end

    describe "#attribute_name" do

      it "is derived from the name" do
        parameter.attribute_name.should == "color"
      end

      it "can be overridden" do
        parameter = described_class.new("COLOR", "hue of choice", :attribute_name => "hue")
        parameter.attribute_name.should == "hue"
      end

    end

    describe "#consume" do

      it "consumes one argument" do
        arguments = %w(a b c)
        parameter.consume(arguments).should == ["a"]
        arguments.should == %w(b c)
      end

      describe "with no arguments" do

        it "raises an Argument error" do
          arguments = []
          lambda do
            parameter.consume(arguments)
          end.should raise_error(ArgumentError)
        end

      end

    end

  end

  describe "optional (name in square brackets)" do

    let(:parameter) do
      described_class.new("[COLOR]", "hue of choice")
    end

    it "is single-valued" do
      parameter.should_not be_multivalued
    end

    describe "#attribute_name" do

      it "omits the brackets" do
        parameter.attribute_name.should == "color"
      end

    end

    describe "#consume" do

      it "consumes one argument" do
        arguments = %w(a b c)
        parameter.consume(arguments).should == ["a"]
        arguments.should == %w(b c)
      end

      describe "with no arguments" do

        it "consumes nothing" do
          arguments = []
          parameter.consume(arguments).should == []
        end

      end

    end

  end

  describe "list (name followed by ellipsis)" do

    let(:parameter) do
      described_class.new("FILE ...", "files to process")
    end

    it "is multi-valued" do
      parameter.should be_multivalued
    end

    describe "#attribute_name" do

      it "gets a _list suffix" do
        parameter.attribute_name.should == "file_list"
      end

    end

    describe "#append_method" do

      it "is derived from the attribute_name" do
        parameter.append_method.should == "append_to_file_list"
      end

    end

    describe "#consume" do

      it "consumes all the remaining arguments" do
        arguments = %w(a b c)
        parameter.consume(arguments).should == %w(a b c)
        arguments.should == []
      end

      describe "with no arguments" do

        it "raises an Argument error" do
          arguments = []
          lambda do
            parameter.consume(arguments)
          end.should raise_error(ArgumentError)
        end

      end

    end

    context "with a weird parameter name, and an explicit attribute_name" do

      let(:parameter) do
        described_class.new("KEY=VALUE ...", "config-settings", :attribute_name => :config_settings)
      end

      describe "#attribute_name" do

        it "is the specified one" do
          parameter.attribute_name.should == "config_settings"
        end

      end

    end

  end

  describe "optional list" do

    let(:parameter) do
      described_class.new("[FILES] ...", "files to process")
    end

    it "is multi-valued" do
      parameter.should be_multivalued
    end

    describe "#attribute_name" do

      it "gets a _list suffix" do
        parameter.attribute_name.should == "files_list"
      end

    end

    describe "#default_value" do

      it "is an empty list" do
        parameter.default_value.should == []
      end

    end

    describe "#help" do

      it "does not include default" do
        parameter.help_rhs.should_not include("default:")
      end

    end

    describe "with specified default value" do

      let(:parameter) do
        described_class.new("[FILES] ...", "files to process", :default => %w(a b c))
      end

      describe "#default_value" do

        it "is that specified" do
          parameter.default_value.should == %w(a b c)
        end

      end

      describe "#help" do

        it "includes the default value" do
          parameter.help_rhs.should include("default:")
        end

      end

      describe "#consume" do

        it "consumes all the remaining arguments" do
          arguments = %w(a b c)
          parameter.consume(arguments).should == %w(a b c)
          arguments.should == []
        end

        describe "with no arguments" do

          it "don't override defaults" do
            arguments = []
            parameter.consume(arguments).should == []
          end

        end

      end

    end

  end

end
