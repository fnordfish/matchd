# frozen_string_literal: true

RSpec.describe Matchd do
  it "has a version number" do
    expect(Matchd::VERSION).not_to be nil
  end

  describe "configure" do
    let(:config) { object_double(Matchd::Config.config) }

    before do
      allow(Matchd::Config).to receive(:configure).and_yield(config)
    end

    it "forwards Matchd::Config" do
      expect(Matchd::Config).to receive(:configure).and_yield(config)
      expect(config).to receive(:dot_dir=).with("~/.my-matchd")
      described_class.configure { |config|
        config.dot_dir = "~/.my-matchd"
      }
    end

    [
      "test_string_config.yml",
      "test_symbol_config.yml"
    ].each do |config_file|
      describe config_file do
        specify do
          expect(config).to receive(:dot_dir=).with("~/.matchd")
          expect(config).to receive(:listen=).with(
            [
              {
                "protocol" => "udp",
                "ip" => "127.0.0.1",
                "port" => 15353
              },
              {
                "protocol" => "udp",
                "ip" => "::1",
                "port" => 15353
              }
            ]
          )
          expect(config).to receive(:resolver=).with(["system", "tcp://1.1.1.1:53"])
          expect(config).to receive(:registry_file=).with("registry.yml")

          described_class.configure_from_file!(fixture_path(config_file))
        end
      end
    end
  end
end
