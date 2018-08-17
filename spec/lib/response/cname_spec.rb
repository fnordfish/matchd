require "response_helper"

RSpec.describe Matchd::Response::CNAME do
  let(:transaction) { instance_double(Async::DNS::Transaction) }

  describe "call" do
    let(:alias_name) { "sample.test" }

    before do
      expect(transaction).to receive(:add).with(
        [instance_of(Resolv::DNS::Resource::IN::CNAME)],
        instance_of(Hash)
      )
    end

    specify "hash initializer" do
      described_class.
        new("alias" => alias_name).
        call(transaction)
    end

    specify "flat initializer" do
      described_class.
        new(alias_name).
        call(transaction)
    end
  end

  context "with resource_options" do
    include_examples "response resource_options", "alias" => "sample.test"
  end

  # TODO: Move this into the "validate" step
  [nil].each do |alias_name|
    context "invalid: #{alias_name.inspect}" do
      subject { described_class.new(alias_name) }
      it "raises an error when called" do
        expect { subject.call(transaction) }.to raise_error(ArgumentError)
      end

      it "is invalid" do
        expect(subject.valid?).to be(false)
      end
    end
  end
end
