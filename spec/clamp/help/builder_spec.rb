# frozen_string_literal: true

require "spec_helper"

describe Clamp::Help::Builder do

  subject(:builder) { described_class.new }

  def output
    builder.string
  end

  describe "#line" do

    it "adds a line of text" do
      builder.line("blah")
      expect(output).to eq("blah\n")
    end

  end

  describe "#row" do

    it "adds two strings separated by spaces" do
      builder.row("LHS", "RHS")
      expect(output).to eq("    LHS    RHS\n")
    end

  end

  context "with multiple rows" do

    before do

      builder.row("foo", "bar")
      builder.row("flibble", "blurk")
      builder.row("x", "y")

    end

    let(:expected_output) do
      [
        "    foo        bar\n",
        "    flibble    blurk\n",
        "    x          y\n"
      ]
    end

    it "arranges them in two columns" do
      expect(output.lines).to eq expected_output
    end

  end

  context "with a mixture of lines and rows" do

    before do

      builder.line("ABCDEFGHIJKLMNOP")
      builder.row("flibble", "blurk")
      builder.line("Another section heading")
      builder.row("x", "y")

    end

    let(:expected_output) do
      [
        "ABCDEFGHIJKLMNOP\n",
        "    flibble    blurk\n",
        "Another section heading\n",
        "    x          y\n"
      ]
    end

    it "still arranges them in two columns" do
      expect(output.lines).to eq expected_output
    end

  end

end
