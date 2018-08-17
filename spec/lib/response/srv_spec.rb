require "response_helper"

RSpec.describe Matchd::Response::SRV do
  let(:transaction) { instance_double(Async::DNS::Transaction) }

  describe "call" do
    before do
      expect(transaction).to receive(:add).with(
        [instance_of(Resolv::DNS::Resource::IN::SRV)],
        instance_of(Hash)
      )
    end

    specify "hash initializer requires string keys" do
      described_class.
        new(
          "target" => "jabber",
          "priority" => 10,
          "weight" => 0,
          "port" => 5269,
          # To make this meaningful, we need to provide a name:
          "name" => "_xmpp-server._tcp.sample.test"
        ).
        call(transaction)
    end
  end

  describe "fail" do
    specify "hash initializer fails with symbol keys" do
      expect {
        described_class.
          new(
            target: "jabber",
            priority: 10,
            weight: 0,
            port: 5269,
            # To make this meaningful, we need to provide a name:
            name: "_xmpp-server._tcp.sample.test"
          )
      }.to raise_error(KeyError)
    end
  end

  context "with resource_options" do
    include_examples "response resource_options",
      "target" => "jabber",
      "priority" => 10,
      "weight" => 0,
      "port" => 5269,
      # To make this meaningful, we need to provide a name:
      "name" => "_xmpp-server._tcp.sample.test"
  end
end
