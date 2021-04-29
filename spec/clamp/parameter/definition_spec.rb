# frozen_string_literal: true

require "spec_helper"

describe Clamp::Parameter::Definition do

  context "when regular" do

    let(:parameter) do
      described_class.new("COLOR", "hue of choice")
    end

    it "has a name" do
      expect(parameter.name).to eq "COLOR"
    end

    it "has a description" do
      expect(parameter.description).to eq "hue of choice"
    end

    it "is single-valued" do
      expect(parameter).not_to be_multivalued
    end

    describe "#attribute_name" do

      it "is derived from the name" do
        expect(parameter.attribute_name).to eq "color"
      end

      it "can be overridden" do
        parameter = described_class.new("COLOR", "hue of choice", attribute_name: "hue")
        expect(parameter.attribute_name).to eq "hue"
      end

    end

    describe "#consume" do

      subject(:consume) { parameter.consume(arguments) }

      context "with arguments" do
        let(:arguments) { %w[a b c] }

        it "returns one consumed argument" do
          expect(consume).to eq ["a"]
        end

        describe "arguments after consume" do

          before do
            consume
          end

          it "has only non-consumed" do
            expect(arguments).to eq %w[b c]
          end

        end

      end

      context "without arguments" do

        let(:arguments) { [] }

        it "raises an Argument error" do
          expect { consume }.to raise_error(ArgumentError)
        end

      end

    end

  end

  context "when optional (name in square brackets)" do

    let(:parameter) do
      described_class.new("[COLOR]", "hue of choice")
    end

    it "is single-valued" do
      expect(parameter).not_to be_multivalued
    end

    describe "#attribute_name" do

      it "omits the brackets" do
        expect(parameter.attribute_name).to eq "color"
      end

    end

    describe "#consume" do

      subject(:consume) { parameter.consume(arguments) }

      context "with arguments" do

        let(:arguments) { %w[a b c] }

        it "returns one consumed argument" do
          expect(consume).to eq ["a"]
        end

        describe "arguments after consume" do

          before do
            consume
          end

          it "has only non-consumed" do
            expect(arguments).to eq %w[b c]
          end

        end
      end

      context "without arguments" do

        let(:arguments) { [] }

        it "consumes nothing" do
          expect(consume).to be_empty
        end

      end

    end

  end

  context "when list (name followed by ellipsis)" do

    let(:parameter) do
      described_class.new("FILE ...", "files to process")
    end

    it "is multi-valued" do
      expect(parameter).to be_multivalued
    end

    describe "#attribute_name" do

      it "gets a _list suffix" do
        expect(parameter.attribute_name).to eq "file_list"
      end

    end

    describe "#append_method" do

      it "is derived from the attribute_name" do
        expect(parameter.append_method).to eq "append_to_file_list"
      end

    end

    describe "#consume" do

      subject(:consume) { parameter.consume(arguments) }

      context "with arguments" do

        let(:arguments) { %w[a b c] }

        it "returns all the consumed arguments" do
          expect(consume).to eq %w[a b c]
        end

        describe "arguments after consume" do

          before do
            consume
          end

          it "empty" do
            expect(arguments).to be_empty
          end

        end

      end

      describe "without arguments" do

        let(:arguments) { [] }

        it "raises an Argument error" do
          expect { consume }.to raise_error(ArgumentError)
        end

      end

    end

    context "with a weird parameter name, and an explicit attribute_name" do

      let(:parameter) do
        described_class.new("KEY=VALUE ...", "config-settings", attribute_name: :config_settings)
      end

      describe "#attribute_name" do

        it "is the specified one" do
          expect(parameter.attribute_name).to eq "config_settings"
        end

      end

    end

  end

  context "when optional list" do

    let(:parameter) do
      described_class.new("[FILES] ...", "files to process")
    end

    it "is multi-valued" do
      expect(parameter).to be_multivalued
    end

    describe "#attribute_name" do

      it "gets a _list suffix" do
        expect(parameter.attribute_name).to eq "files_list"
      end

    end

    describe "#default_value" do

      it "is an empty list" do
        expect(parameter.default_value).to be_empty
      end

    end

    describe "#help" do

      it "does not include default" do
        expect(parameter.help_rhs).not_to include("default:")
      end

    end

    context "with specified default value" do

      let(:parameter) do
        described_class.new("[FILES] ...", "files to process", default: %w[a b c])
      end

      describe "#default_value" do

        it "is that specified" do
          expect(parameter.default_value).to eq %w[a b c]
        end

      end

      describe "#help" do

        it "includes the default value" do
          expect(parameter.help_rhs).to include("default:")
        end

      end

      describe "#consume" do

        subject(:consume) { parameter.consume(arguments) }

        context "with arguments" do

          let(:arguments) { %w[a b c] }

          it "returns all the consumed arguments" do
            expect(consume).to eq %w[a b c]
          end

          describe "arguments after consume" do

            before do
              consume
            end

            it "empty" do
              expect(arguments).to be_empty
            end

          end

        end

        context "without arguments" do

          let(:arguments) { [] }

          it "don't override defaults" do
            expect(consume).to be_empty
          end

        end

      end

    end

  end

end
