require "response_helper"

RSpec.describe Matchd::Response::PTR do
  let(:transaction) { instance_double(Async::DNS::Transaction) }

  describe "call" do
    let(:ptr_host) { "host1.sample.test" }

    before do
      expect(transaction).to receive(:add).with(
        [instance_of(Resolv::DNS::Resource::IN::PTR)],
        instance_of(Hash)
      )
    end

    specify "hash initializer" do
      described_class.
        new("host" => ptr_host).
        call(transaction)
    end

    specify "flat initializer" do
      described_class.
        new(ptr_host).
        call(transaction)
    end
  end

  context "with resource_options" do
    include_examples "response resource_options", "host" => "host1.sample.test"
  end

  # TODO: Move this into the "validate" step
  [nil].each do |ptr_host|
    context "invalid: #{ptr_host.inspect}" do
      subject { described_class.new(ptr_host) }
      it "raises an error when called" do
        expect { subject.call(transaction) }.to raise_error(ArgumentError)
      end

      it "is invalid" do
        expect(subject.valid?).to be(false)
      end
    end
  end
end
