# frozen_string_literal: true

require "matchd"

module Matchd::CLI
  class Main < Thor
    package_name "Matchd"

    include ConfigFileOption

    desc "start [options]", "Start the matchd dns service"
    option :deamonize,
      default: true,
      type: :boolean,
      desc: "Start as background daemon."
    def start
      Matchd::Control.new.start(ontop: !options[:deamonize])
    end

    desc "stop", "Stop the running matchd dns daemon"
    def stop
      Matchd::Control.new.stop
    end

    desc "status", "Print process status information"
    def status
      Matchd::Control.new.status
    end

    desc "restart", "Restart the running matchd daemon"
    long_desc "Stop and Start with new options. " \
              "This is the same as running stop and start successively.\n\n" \
              "If your configuration changes the 'dot_dir' you'll need to stop using the old config and start with the new one."
    option :deamonize,
      default: true,
      type: :boolean,
      desc: "Restart as background daemon.",
      long_desc: ""
    def restart
      invoke :stop
      invoke :start
    end

    desc "config SUBCOMMAND ...ARGS", "manage configuration files"
    subcommand "config", Config
  end
end
