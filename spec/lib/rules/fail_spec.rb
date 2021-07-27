# frozen_string_literal: true

RSpec.describe Matchd::Rule::Fail do
  let(:options) do
    { "match" => //, "resource_class" => "ANY" }
  end

  [:NXDomain, "NXDomain"].each do |failure_name|
    context "using error name #{failure_name.inspect}" do
      subject { described_class.new(options.merge("fail" => failure_name)) }

      specify { expect(subject.instance_variable_get(:@fail)).to eq(failure_name) }
      specify { expect(subject.rcode).to eq(Resolv::DNS::RCode::NXDomain) }
    end
  end

  context "using error magic number" do
    subject { described_class.new(options.merge("fail" => failure_name)) }

    let(:failure_name) { 3 }

    specify { expect(subject.instance_variable_get(:@fail)).to eq(failure_name) }
    specify { expect(subject.rcode).to eq(failure_name) }
  end

  describe "#visit!" do
    subject { described_class.new(options.merge("fail" => :NXDomain)) }

    let(:server) { instance_double(Matchd::Server) }
    let(:name) { "example.com" }
    let(:resource_class) { Resolv::DNS::Resource::IN::A }
    let(:transaction) { instance_double(Async::DNS::Transaction) }

    specify do
      expect(transaction).to receive(:fail!).with(Resolv::DNS::RCode::NXDomain)
      subject.visit!(server, name, resource_class, transaction)
    end
  end
end
