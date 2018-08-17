RSpec.describe Matchd::Rule::Respond do
  subject { described_class.new(rule) }

  let(:rule) do
    {
      "match" => //,
      "resource_class" => "A",
      "respond" => responses_config
    }
  end

  let(:responses_config) do
    [
      "10.0.0.80",
      {
        "resource_class" => "CNAME",
        "alias" => "foo.bar"
      }
    ]
  end

  let(:responses) do
    [
      instance_double(Matchd::Response::A,
        ip: "10.0.0.80",
        resource_options: {}),
      instance_double(Matchd::Response::CNAME,
        alias_name: "foo.bar",
        resource_options: {})
    ]
  end

  let(:server) { instance_double(Matchd::Server) }
  let(:transaction) { instance_double(Async::DNS::Transaction) }
  let(:query_name) { "test.dev." }
  let(:query_ressource) { Resolv::DNS::Resource::IN::A }

  it { expect(subject.responses).to eq(responses_config) }

  describe "#visit!" do
    specify "creates Response classes using it's factory" do
      responses.each { |r| expect(r).to receive(:call).with(transaction) }

      expect(Matchd).to receive(:Response).with(responses_config, ["A"]).and_return(responses)

      subject.visit!(server, query_name, query_ressource, transaction)
    end
  end
end
