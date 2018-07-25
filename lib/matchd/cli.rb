require "thor"

module Matchd
  module CLI
    autoload :ConfigFileOption, "matchd/cli/config_file_option"

    autoload :Config, "matchd/cli/config"
    autoload :Main,   "matchd/cli/main"
  end
end
