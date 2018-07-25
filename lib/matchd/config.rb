require "yaml"
require "dry-configurable"

module Matchd
  module Config
    DEFAULT_DOT_DIR = File.join(ENV["HOME"], ".matchd")
    DEFAULT_CONFIG_FILE = File.join(DEFAULT_DOT_DIR, "config.yml")

    extend Dry::Configurable

    # Base directory for config and daemon files
    setting(:dot_dir, DEFAULT_DOT_DIR, reader: true) { |f| File.expand_path(f) }

    # where the server will listen on
    setting(
      :listen,
      [
        { "protocol" => "udp", "ip" => "127.0.0.1", "port" => 15353 },
        { "protocol" => "udp", "ip" => "::1",       "port" => 15353 }
      ],
      reader: true
    )

    # The upstream resolver for passthrough requests.
    # "system" will try to read your systems DNS setup.
    # Give a specific config like this:
    #
    #   [{"protocol" => "udp", "ip" => "1.1.1.1", "port" => 53},
    #    {"protocol" => "tcp", "ip" => "1.1.1.1", "port" => 53}]
    #
    setting(:resolver, "system", reader: true)

    setting(:registry_file, "registry.yml")
    def self.registry_file
      File.expand_path(config.registry_file, dot_dir)
    end
  end
end
