# frozen_string_literal: true

RSpec.describe Matchd::Glue::AsyncEndpoint do
  describe "classic array triplet" do
    let(:single) { [:udp, "0.0.0.0", 53] }
    let(:single_wrapped) { [[:udp, "0.0.0.0", 53]] }
    let(:multiple) { [[:udp, "0.0.0.0", 53], [:tcp, "0.0.0.0", 53]] }

    specify "single" do
      expect(described_class.parse(single)).to eq(
        [[:udp, "0.0.0.0", 53]]
      )
    end

    specify "single wrapped" do
      expect(described_class.parse(single_wrapped)).to eq(
        [[:udp, "0.0.0.0", 53]]
      )
    end

    specify "multiple" do
      expect(described_class.parse(multiple)).to eq(
        [[:udp, "0.0.0.0", 53], [:tcp, "0.0.0.0", 53]]
      )
    end

    describe "invalid input" do
      specify "empty array" do
        expect(described_class.parse([])).to eq(nil)
      end
    end
  end

  describe "Hash" do
    let(:symbol_keys) { { protocol: :udp, ip: "0.0.0.0", port: 53 } }
    let(:string_keys) { { "protocol" => :udp, "ip" => "0.0.0.0", "port" => 53 } }

    let(:mixed_keys) { { protocol: :udp, "ip" => "0.0.0.0", "port" => 53 } }

    specify "symbol_keys" do
      expect(described_class.parse(symbol_keys)).to eq(
        [[:udp, "0.0.0.0", 53]]
      )
    end

    specify "string_keys" do
      expect(described_class.parse(string_keys)).to eq(
        [[:udp, "0.0.0.0", 53]]
      )
    end

    specify "mixed_keys" do
      expect(described_class.parse(mixed_keys)).to eq(
        [[:udp, "0.0.0.0", 53]]
      )
    end

    specify "Hash in array" do
      expect(described_class.parse([symbol_keys])).to eq([[:udp, "0.0.0.0", 53]])
    end

    [
      { protocol: :udp, ip: "0.0.0.0", port: nil },
      { protocol: :udp, ip: "0.0.0.0" }
    ].each do |data|
      specify "missing port gets replaced with default" do
        expect(described_class.parse(data)).to eq([[:udp, "0.0.0.0", 53]])
      end
    end

    [

      { protocol: :udp, ip: nil,       port: 53 },
      { protocol: :udp, ip: nil,       port: nil },
      { protocol: nil,  ip: "0.0.0.0", port: 53 },
      { protocol: nil,  ip: "0.0.0.0", port: nil },
      { protocol: nil,  ip: nil,       port: 53 },
      { protocol: nil,  ip: nil,       port: nil },

      { protocol: :udp, port: 53 },
      { protocol: :udp,                        },
      {                ip: "0.0.0.0", port: 53 },
      {                ip: "0.0.0.0", },
      { port: 53 },
      {},
    ].each do |data|
      specify "invalid missing data: #{data.inspect}" do
        expect(described_class.parse(data)).to eq(nil)
      end
    end
  end

  describe "URI string" do
    specify do
      expect(described_class.parse("udp://0.0.0.0:53")).to eq(
        [[:udp, "0.0.0.0", 53]]
      )
    end

    specify do
      expect(described_class.parse("tcp://0.0.0.0:53")).to eq(
        [[:tcp, "0.0.0.0", 53]]
      )
    end

    specify do
      expect(described_class.parse(["udp://0.0.0.0:53", "tcp://0.0.0.0:53"])).to eq(
        [[:udp, "0.0.0.0", 53], [:tcp, "0.0.0.0", 53]]
      )
    end

    specify "missing port gets replaced with default" do
      expect(described_class.parse(["udp://0.0.0.0", "tcp://0.0.0.0"])).to eq(
        [[:udp, "0.0.0.0", 53], [:tcp, "0.0.0.0", 53]]
      )
    end
  end

  describe "All in one" do
    specify do
      expect(
        described_class.parse(
          [
            "udp://0.0.0.1:53",
            [:tcp, "0.0.0.2", 53],
            { "protocol" => :udp, "ip" => "0.0.0.3", "port" => 53 }
          ]
        )
      ).to eq(
        [
          [:udp, "0.0.0.1", 53],
          [:tcp, "0.0.0.2", 53],
          [:udp, "0.0.0.3", 53]
        ]
      )
    end

    specify do
      expect(
        described_class.parse(
          ["udp://0.0.0.1:53", ["tcp", "0.0.0.2", 53]]
        )
      ).to eq(
        [
          [:udp, "0.0.0.1", 53],
          [:tcp, "0.0.0.2", 53]
        ]
      )
    end
  end
end
