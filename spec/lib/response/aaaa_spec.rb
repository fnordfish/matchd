require "response_helper"

RSpec.describe Matchd::Response::AAAA do
  let(:transaction) { instance_double(Async::DNS::Transaction) }

  describe "call" do
    let(:ip) { "::1" }

    before do
      expect(transaction).to receive(:add).with(
        [instance_of(Resolv::DNS::Resource::IN::AAAA)],
        instance_of(Hash)
      )
    end

    specify "hash initializer" do
      described_class.
        new("ip" => ip).
        call(transaction)
    end

    specify "flat initializer" do
      described_class.
        new(ip).
        call(transaction)
    end
  end

  context "with resource_options" do
    include_examples "response resource_options", "ip" => "::1"
  end

  # TODO: Move this into the "validate" step
  ["not-an-ip", "", nil, "1.2.3.4"].each do |ip|
    context "invalid: #{ip.inspect}" do
      subject { described_class.new(ip) }
      it "raises an error when called" do
        expect { subject.call(transaction) }.to raise_error(ArgumentError)
      end

      it "is invalid" do
        expect(subject.valid?).to be(false)
      end
    end
  end
end
