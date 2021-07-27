# frozen_string_literal: true

RSpec.describe Matchd::Response do
  describe "#Response factory" do
    context "with resource_class configs" do
      subject { Matchd::Response(responses_config, fallback_resource_class) }

      let(:fallback_resource_class) { nil }
      let(:responses_config) do
        [
          {
            "resource_class" => "A",
            "ip" => "10.0.0.80",
          },
          {
            "resource_class" => "CNAME",
            "alias" => "foo.bar"
          }
        ]
      end

      specify do
        expect(subject[0]).to be_an_instance_of(Matchd::Response::A).and have_attributes(ip: "10.0.0.80")
        expect(subject[1]).to be_an_instance_of(Matchd::Response::CNAME).and have_attributes(alias_name: "foo.bar")
      end
    end

    context "with fallback_resource_class" do
      specify "Array<Hash> responses config, Single fallback_resource_class" do
        subject = Matchd::Response([{ "ip" => "10.0.0.80" }], "A")
        expect(subject.size).to eq(1)
        expect(subject[0]).to be_an_instance_of(Matchd::Response::A).and have_attributes(ip: "10.0.0.80")
      end

      specify "Array<Hash> responses config, Array fallback_resource_class" do
        subject = Matchd::Response([{ "ip" => "10.0.0.80" }], ["A"])
        expect(subject.size).to eq(1)
        expect(subject[0]).to be_an_instance_of(Matchd::Response::A).and have_attributes(ip: "10.0.0.80")
      end

      specify "Array<pure data> responses config, Array fallback_resource_class" do
        subject = Matchd::Response(["10.0.0.80"], ["A"])
        expect(subject.size).to eq(1)
        expect(subject[0]).to be_an_instance_of(Matchd::Response::A).and have_attributes(ip: "10.0.0.80")
      end
    end

    context "missing fallback_resource_class" do
      it "raises ArgumentError" do
        expect { Matchd::Response(["10.0.0.80"], nil) }.to raise_error(ArgumentError, "Missing resource_class for Response")
      end
    end
  end

  describe "is an abstract class" do
    subject { described_class.new({}) }

    let(:transaction) { instance_double(Async::DNS::Transaction) }

    specify do
      expect { subject.call(transaction) }.to raise_error(Matchd::Response::NotImplementedError)
    end
  end
end
