# frozen_string_literal: true

RSpec.describe Matchd::Helpers do
  describe "#extract_options" do
    let(:input) do
      {
        "foo" => "foo",
        :bar => :bar,
        "nil" => nil
      }
    end

    specify "missing key will be ignored" do
      expect(described_class.extract_options(["missing"], input)).to eq({})
    end

    specify "nil value will get extracted" do
      expect(described_class.extract_options(["nil"], input)).to eq(nil: nil)
    end

    specify "keys will get symbolized" do
      expect(described_class.extract_options(["foo"], input)).to eq(foo: "foo")
    end

    specify "exact key lookup" do
      expect(described_class.extract_options(["bar"], input)).to eq({})
      expect(described_class.extract_options([:bar], input)).to eq(bar: :bar)
    end

    specify "keys will take new order" do
      expect(described_class.extract_options([:bar, "foo"], input)).to eq(bar: :bar, foo: "foo")
    end
  end
end
