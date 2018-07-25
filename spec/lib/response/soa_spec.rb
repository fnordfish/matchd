require "response_helper"

RSpec.describe Matchd::Response::SOA do
  let(:transaction) { instance_double(Async::DNS::Transaction) }

  describe "call" do
    before do
      expect(transaction).to receive(:add).with(
        [instance_of(Resolv::DNS::Resource::IN::SOA)],
        instance_of(Hash)
      )
    end

    specify "hash initializer requires string keys" do
      described_class.
        new(
          "mname" => "ns1.sample.dev.",
          "rname" => "admin.sample.dev.",
          "serial" => "1533038712",
          "refresh" => 1200,
          "retry" => 900,
          "expire" => 3_600_000,
          "minimum_ttl" => 172_800
        ).
        call(transaction)
    end
  end

  describe "fail" do
    specify "hash initializer fails with symbol keys" do
      expect {
        described_class.
          new(
            mname: "ns1.sample.dev.",
            rname: "admin.sample.dev.",
            serial: "1533038712",
            refresh: 1200,
            retry: 900,
            expire: 3_600_000,
            minimum_ttl: 172_800
          )
      }.to raise_error(KeyError)
    end
  end

  context "with resource_options" do
    include_examples "response resource_options",
      "mname" => "ns1.sample.dev.",
      "rname" => "admin.sample.dev.",
      "serial" => "1533038712",
      "refresh" => 1200,
      "retry" => 900,
      "expire" => 3_600_000,
      "minimum_ttl" => 172_800
  end
end
