require "response_helper"

RSpec.describe Matchd::Response::MX do
  let(:transaction) { instance_double(Async::DNS::Transaction) }

  describe "call" do
    before do
      expect(transaction).to receive(:add).with(
        [instance_of(Resolv::DNS::Resource::IN::MX)],
        instance_of(Hash)
      )
    end

    specify "hash initializer requires string keys" do
      described_class.
        new(
          "preference" => 10,
          "host" => "mail.sample.dev"
        ).
        call(transaction)
    end
  end

  describe "fail" do
    specify "hash initializer fails with symbol keys" do
      expect {
        described_class.
          new(
            preference: 10,
            host: "mail.sample.dev"
          )
      }.to raise_error(KeyError)
    end

    specify "no flat initializer" do
      expect {
        described_class.
          new("mail.sample.dev")
      }.to raise_error(NoMethodError)
    end
  end

  context "with resource_options" do
    include_examples "response resource_options",
      "preference" => 10,
      "host" => "mail.sample.dev"
  end

  # TODO: Move this into the "validate" step
  [
    { "preference" => 10, "host" => nil },
    { "preference" => nil, "host" => "mail.sample.dev" }
  ].each do |opts|
    context "invalid: #{opts.inspect}", skip: "waiting for better response validations" do
      subject { described_class.new(opts) }

      it "raises an error when called" do
        expect { subject.call(transaction) }.to raise_error(ArgumentError)
      end

      it "is invalid" do
        expect(subject.valid?).to be(false)
      end
    end
  end
end
