require "matchd/version"

module Matchd
  autoload :Config,   "matchd/config"
  autoload :Control,  "matchd/control"
  autoload :Glue,     "matchd/glue"
  autoload :Helpers,  "matchd/helpers"
  autoload :Registry, "matchd/registry"
  autoload :Response, "matchd/response"
  autoload :Rule,     "matchd/rule"
  autoload :Server,   "matchd/server"

  def self.configure(&block)
    Config.configure(&block)
  end

  def self.configure_from_file!(config_file = Config::DEFAULT_CONFIG_FILE)
    Config.configure do |config|
      YAML.load_file(config_file).each do |k, v|
        config.public_send("#{k}=", v)
      end
    end
  end

  def self.root
    File.expand_path('..', __dir__)
  end

  extend Response::Factory
  extend Rule::Factory
end
