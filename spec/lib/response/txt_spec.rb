# frozen_string_literal: true

require "response_helper"

RSpec.describe Matchd::Response::TXT do
  let(:transaction) { instance_double(Async::DNS::Transaction) }

  describe "call" do
    let(:txt) { "some-token=value" }

    before do
      expect(transaction).to receive(:add).with(
        [instance_of(Resolv::DNS::Resource::IN::TXT)],
        instance_of(Hash)
      )
    end

    specify "hash initializer" do
      described_class.
        new("txt" => txt).
        call(transaction)
    end

    specify "flat initializer" do
      described_class.
        new(txt).
        call(transaction)
    end
  end

  context "with resource_options" do
    include_examples "response resource_options", "txt" => "some-token=value"
  end

  # TODO: Move this into the "validate" step
  [nil].each do |txt|
    context "invalid: #{txt.inspect}", skip: "waiting for better response validations" do
      subject { described_class.new(txt) }

      it "raises an error when called" do
        expect { subject.call(transaction) }.to raise_error(ArgumentError)
      end

      it "is invalid" do
        expect(subject.valid?).to be(false)
      end
    end
  end
end
