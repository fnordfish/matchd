RSpec.describe Matchd::Registry do
  describe "single file" do
    let(:registry_file) { fixture_path "test_dns_1.yml" }

    subject { described_class.load_file(registry_file) }

    let(:expected) do
      [
        {
          class: Matchd::Rule::Append,
          match_name: /dev.mydomain.org/,
          match_resource_classes: [Resolv::DNS::Resource::IN::ANY],
          append_questions: ["A", "CNAME", "MX", "NS"]
        },
        {
          class: Matchd::Rule::Respond,
          match_name: "dev.mydomain.org",
          match_resource_classes: [Resolv::DNS::Resource::IN::A],
          responses: "10.0.0.80"
        },
        {
          class: Matchd::Rule::Respond,
          match_name: /^(\w+\.)*mydomain\.test$/,
          match_resource_classes: [Resolv::DNS::Resource::IN::A],
          responses: "10.0.0.80"
        },
        {
          class: Matchd::Rule::Respond,
          match_name: /^(\w+\.)*mydomain\.test$/,
          match_resource_classes: [Resolv::DNS::Resource::IN::AAAA],
          responses: "fe80::A:0:0:0050"
        },
        {
          class: Matchd::Rule::Respond,
          match_name: "_sometxt.mydomain.test",
          match_resource_classes: [Resolv::DNS::Resource::IN::TXT],
          responses: { "txt" => "Located in a black hole=Likely to be eaten by a grue" }
        },
        {
          class: Matchd::Rule::Respond,
          match_name: "80.0.0.10.in-addr.arpa",
          match_resource_classes: [Resolv::DNS::Resource::IN::PTR],
          responses: { "host" => "dev.mydomain.org." }
        },
        {
          class: Matchd::Rule::Respond,
          match_name: "dev.mydomain.org",
          match_resource_classes: [Resolv::DNS::Resource::IN::MX],
          responses: { "preference" => 10, "host" => "mail.mydomain.org." }
        },
        {
          class: Matchd::Rule::Respond,
          match_name: "mydomain.org",
          match_resource_classes: [Resolv::DNS::Resource::IN::NS],
          responses: [
            { "host" => "ns1.mydomain.org." },
            { "host" => "ns2.mydomain.org." }
          ]
        }
      ]
    end

    it "reads in registry file in order" do
      subject.each_with_index { |item, i| expect(item).to have_attributes(expected[i]) }
    end
  end

  describe "loading errors" do
    specify "missing file" do
      expect {
        registry_file = fixture_path("not_a_file.yml")
        described_class.load_file(registry_file)
      }.to raise_error(Matchd::Registry::LoadError, /does not exist/)
    end

    specify "missing rules key from file" do
      expect {
        registry_file = fixture_path("test_invalid_missing_rules.yml")
        described_class.load_file(registry_file)
      }.to raise_error(Matchd::Registry::ParseError, /Missing 'rules' key.*test_invalid_missing_rules\.yml/)
    end

    specify "missing rules key" do
      expect {
        described_class.load(
          "version" => 1,
          "some" => {
            "other" => "nonesence"
          }
        )
      }.to raise_error(Matchd::Registry::ParseError, /Missing 'rules' key/)
    end
  end

  shared_examples "valid rule data" do |parsed_data|
    let(:registry) { described_class.load(parsed_data) }
    it { expect { registry }.to_not raise_error }
    it { expect(registry.to_a).to_not include a_kind_of(Matchd::Rule::Invalid) }
    it { expect(registry).to be_valid }
  end

  context "nil rules" do
    include_examples "valid rule data", "version" => 1, "rules" => nil
  end

  context "empty array rules" do
    include_examples "valid rule data", "version" => 1, "rules" => []
  end

  context "single rules hash" do
    include_examples "valid rule data", "version" => 1, "rules" => {
      "match" => "dev.mydomain.org",
      "resource_class" => "A",
      "respond" => "10.0.0.80"
    }
  end

  shared_examples "invalid rule data" do |parsed_data|
    let(:registry) { described_class.load(parsed_data) }
    it { expect { registry }.to_not raise_error }
    it { expect(registry.first).to be_a(Matchd::Rule::Invalid) }
    it { expect(registry).to_not be_valid }
  end

  context "some string rule" do
    include_examples "invalid rule data",
      "version" => 1,
      "rules" => "not a a rule"
  end

  context "some non-rule-ish Hash" do
    include_examples "invalid rule data",
      "version" => 1,
      "rules" => { "I'm" => "not a a rule" }
  end

  context "array of nil rules" do
    include_examples "invalid rule data",
      "version" => 1,
      "rules" => [nil, nil]
  end
end
