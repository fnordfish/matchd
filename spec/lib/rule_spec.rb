RSpec.describe Matchd::Rule do
  describe "parse_match" do
    {
      '/(^\w+\.)*mydomain\.test$/' => /(^\w+\.)*mydomain\.test$/,
      '/(^\w+\.)*mydomain\.test$/i' => /(^\w+\.)*mydomain\.test$/i,
      %q{/\A
          [[:digit:]]+ # 1 or more digits before the decimal point
          (\.          # Decimal point
              [[:digit:]]+ # 1 or more digits after the decimal point
          )? # The decimal point and following digits are optional
      \Z/mix} => /\A
          [[:digit:]]+ # 1 or more digits before the decimal point
          (\.          # Decimal point
              [[:digit:]]+ # 1 or more digits after the decimal point
          )? # The decimal point and following digits are optional
      \Z/mix
    }.each do |str, regexp|
      specify "parsing regexp lookalike string #{str.inspect} into Regexp" do
        parsed = described_class.parse_match(str)
        expect(parsed).to be_a(Regexp)
        expect(parsed).to eq(regexp)
      end
    end

    [
      '^missing\.slashes$',
      '/missing.ending.slash',
      'missing-leasing-slash/',
      '/unsuported-regexp-options/narf',
      '%r{unsupported.regexp.sytle}'
    ].each do |str|
      specify "parses as exact string match" do
        parsed = described_class.parse_match(str)
        expect(parsed).to be_a(String)
        expect(parsed).to eq(str)
      end
    end

    specify "Regexp input returns input" do
      input = /(^\w+\.)*mydomain\.test$/
      parsed = described_class.parse_match(input)

      expect(parsed).to be_a(Regexp)
      expect(parsed).to eq(input)
    end
  end

  describe "Rule" do
    subject { Matchd.Rule(data) }

    ["", nil, []].each do |rule_data|
      describe "empty rule: #{rule_data.inspect}" do
        let(:data) { rule_data }
        specify { expect(subject).to be_a(Matchd::Rule::Invalid) }
        specify { expect(subject.raw).to eq(data) }
      end
    end

    {
      "respond" => Matchd::Rule::Respond,
      "append_question" => Matchd::Rule::Append,
      "passthrough" => Matchd::Rule::Passthrough,
      "fail" => Matchd::Rule::Fail,
      # invalid stuff
      "" => Matchd::Rule::Invalid,
      "not-a-rule" => Matchd::Rule::Invalid,
      nil => Matchd::Rule::Invalid,
      [] => Matchd::Rule::Invalid,
      {} => Matchd::Rule::Invalid
    }.each do |key, rule_class|
      describe "#{key} maps to #{rule_class}" do
        let(:data) do
          {
            "match" => //,
            "resource_class" => "ANY",
            key => double("some #{key} data")
          }
        end

        specify { expect(subject).to be_a(rule_class) }
        specify { expect(subject.raw).to eq(data) }
      end
    end
  end

  describe "call" do
    subject do
      described_class.new(
        "match" => //,
        "resource_class" => "ANY"
      )
    end

    let(:server) { instance_double(Matchd::Server) }
    let(:transaction) { instance_double(Async::DNS::Transaction) }
    let(:query_name) { "test.test." }
    let(:query_ressource) { Resolv::DNS::Resource::IN::A }

    describe "matches" do
      before { expect(subject).to receive(:matches?).and_return(true) }

      it "calls visit! and forwards all arguments" do
        visit_retval = "visit_return_value"

        expect(subject).to receive(:visit!).with(
          server, query_name, query_ressource, transaction
        ).once.and_return(visit_retval)

        expect(
          subject.call(server, query_name, query_ressource, transaction)
        ).to eql(visit_retval)
      end
    end

    describe "not a match" do
      before { expect(subject).to receive(:matches?).and_return(false) }

      it "does not call visit! and returns false" do
        expect(subject).to receive(:visit!).never
        expect(
          subject.call(server, query_name, query_ressource, transaction)
        ).to eq(false)
      end
    end
  end
end
