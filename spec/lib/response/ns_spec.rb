require "response_helper"

RSpec.describe Matchd::Response::NS do
  let(:transaction) { instance_double(Async::DNS::Transaction) }

  describe "call" do
    let(:ns_host) { "ns1.sample.dev" }

    before do
      expect(transaction).to receive(:add).with(
        [instance_of(Resolv::DNS::Resource::IN::NS)],
        instance_of(Hash)
      )
    end

    specify "hash initializer" do
      described_class.
        new("host" => ns_host).
        call(transaction)
    end

    specify "flat initializer" do
      described_class.
        new(ns_host).
        call(transaction)
    end
  end

  context "with resource_options" do
    include_examples "response resource_options", "host" => "ns1.sample.dev"
  end

  # TODO: Move this into the "validate" step
  [nil].each do |ns_host|
    context "invalid: #{ns_host.inspect}" do
      subject { described_class.new(ns_host) }
      it "raises an error when called" do
        expect { subject.call(transaction) }.to raise_error(ArgumentError)
      end

      it "is invalid" do
        expect(subject.valid?).to be(false)
      end
    end
  end
end
