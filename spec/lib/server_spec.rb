# frozen_string_literal: true

RSpec.describe Matchd::Server do
  subject do
    described_class.new(registry, [[:udp, "127.0.0.1", 63333]])
  end

  let(:registry) { instance_double(Matchd::Registry) }
  let(:transaction) { instance_double(Async::DNS::Transaction) }
  let(:query_name) { "test.test." }
  let(:query_ressource) { Resolv::DNS::Resource::IN::A }

  describe "default fallback" do
    it "done if rule found" do
      expect(registry).to receive(:any?).and_return(true)
      subject.process(query_name, query_ressource, transaction)
    end

    it "passthrough if none found" do
      expect(registry).to receive(:any?).and_return(false)
      expect(subject).to receive(:passthrough!).with(query_name, query_ressource, transaction)
      subject.process(query_name, query_ressource, transaction)
    end
  end

  specify "passthrough!" do
    passthroug_rule = instance_double(Matchd::Rule::Passthrough)
    expect(Matchd::Rule::Passthrough).to receive(:new).and_wrap_original do |m, *args|
      m.call(*args)   # call the original
      passthroug_rule # but return the instance double
    end

    expect(passthroug_rule).to receive(:visit!).with(subject, query_name, query_ressource, transaction)

    subject.passthrough!(query_name, query_ressource, transaction)
  end
end
