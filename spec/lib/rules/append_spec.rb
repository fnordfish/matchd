# frozen_string_literal: true

# - match: /dev.mydomain.org/
#   resource_class: ANY
#   append_question:
#     - A
#     - CNAME
#     - MX
#     - NS
RSpec.describe Matchd::Rule::Append do
  subject { described_class.new(options) }

  let(:options) do
    { "match" => //, "resource_class" => "ANY", "append_question" => append_question }
  end
  let(:server) { instance_double(Matchd::Server) }
  let(:name) { "example.test" }
  let(:resource_class) { Resolv::DNS::Resource::IN::ANY }
  let(:transaction) { instance_double(Async::DNS::Transaction, name: name) }

  let(:append_question) { %w(A CNAME MX NS) }

  describe "#visit!" do
    context "without additional transaction options" do
      specify do
        expect(transaction).to receive(:append_question!)
        expect(transaction).to receive(:append!).with(name, ::Resolv::DNS::Resource::IN::A, {})
        expect(transaction).to receive(:append!).with(name, ::Resolv::DNS::Resource::IN::CNAME, {})
        expect(transaction).to receive(:append!).with(name, ::Resolv::DNS::Resource::IN::MX, {})
        expect(transaction).to receive(:append!).with(name, ::Resolv::DNS::Resource::IN::NS, {})

        subject.visit!(server, name, resource_class, transaction)
      end
    end

    context "with additional transaction options" do
      let(:options) do
        { "match" => //,
          "resource_class" => "ANY",
          "append_question" => {
            "resource_class" => append_question,
            "ttl" => 3600,
            "name" => "www.example.com.",
            "section" => "additional"
          } }
      end

      specify do
        expect(subject.transaction_options).to eq(
          ttl: 3600,
          name: "www.example.com.",
          section: "additional"
        )
        expect(transaction).to receive(:append_question!)
        expect(transaction).to receive(:append!).with(name, ::Resolv::DNS::Resource::IN::A,     subject.transaction_options)
        expect(transaction).to receive(:append!).with(name, ::Resolv::DNS::Resource::IN::CNAME, subject.transaction_options)
        expect(transaction).to receive(:append!).with(name, ::Resolv::DNS::Resource::IN::MX,    subject.transaction_options)
        expect(transaction).to receive(:append!).with(name, ::Resolv::DNS::Resource::IN::NS,    subject.transaction_options)

        subject.visit!(server, name, resource_class, transaction)
      end
    end
  end
end
