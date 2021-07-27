# frozen_string_literal: true

module Matchd::CLI
  class Config < Thor
    include Thor::Actions

    add_runtime_options!
    class_option :verbose, type: :boolean, aliases: "-v", group: :runtime,
                           desc: "Print out additional logging information"

    desc "setup [options]", "Creates the basic configuration files"
    option :base,
      aliases: "-b",
      type: :string,
      default: Matchd::Config::DEFAULT_DOT_DIR,
      desc: "the base directory for all config files"
    option :config_file,
      aliases: "-C",
      type: :string,
      default: Matchd::Config::DEFAULT_CONFIG_FILE,
      desc: "Name of the config file to create. Relative to 'base' or absolute path"
    def setup
      opts = options.dup

      dot_dir     = File.expand_path(opts.delete(:base))
      config_file = File.expand_path(opts.delete(:config_file), dot_dir)

      Matchd.configure { |c| c.dot_dir = dot_dir }

      empty_directory(dot_dir, opts)

      create_file(config_file, YAML.dump(Matchd::Config.config.to_h), opts)

      sample_registry = File.expand_path(File.join("examples", "registry.yml"), Matchd.root)
      create_file(Matchd::Config.registry_file, File.binread(sample_registry), opts)
    end
  end
end
