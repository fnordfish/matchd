# frozen_string_literal: true

require "daemons"

module Matchd
  # Controls the demonizing of a {Matchd::Server}
  class Control
    def initialize(options = {})
      @name = options.delete(:name, "matchd")
    end

    def start(options = {})
      run! "start", ontop: options.fetch(:ontop, false)
    end

    def stop
      run! "stop"
    end

    def status
      run! "status"
    end

    def restart(options = {})
      stop
      start(options)
    end

    # @private
    def run!(argv, options = {})
      run_options = { ARGV: Array(argv), **options, **daemon_opts }
      Daemons.run_proc(@name, run_options) do
        require "matchd/server"
        Matchd::Server.new(*server_opts).run
      end
    end

    # @private
    def server_opts
      [
        Matchd::Registry.load_file(Matchd::Config.registry_file),
        Matchd::Config.listen,
        { resolver: Matchd::Config.resolver }
      ]
    end

    # @private
    def daemon_opts
      daemon_dir = Matchd::Config.dot_dir
      {
        dir_mode: :normal,
        dir: daemon_dir,
        log_output: true,
        log_dir: daemon_dir
      }
    end
  end
end
