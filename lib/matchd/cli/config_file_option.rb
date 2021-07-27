# frozen_string_literal: true

module Matchd::CLI
  # A little patch to allow a "class_option" for letting Matchd be configured
  # using the given or default config file
  module ConfigFileOption
    def self.included(receiver)
      receiver.class_exec do
        class_option :config,
          type: :string,
          aliases: "-c",
          group: :runtime,
          default: Matchd::Config::DEFAULT_CONFIG_FILE,
          desc: "The config file to read"

        no_commands do
          def initialize(args = [], local_options = {}, config = {})
            super
            Matchd.configure_from_file!(options[:config]) if File.file?(options[:config])
          end
        end
      end
    end
  end
end
