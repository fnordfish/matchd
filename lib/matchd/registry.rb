require "yaml"

module Matchd
  # Tthe dns pattern registry
  # It basically delegates everything to a YAML::Store but handles the conversion
  # of Regexp dns-patterns into YAML string keys and reverse.
  class Registry
    include Enumerable

    LoadError = Class.new(RuntimeError)

    class ParseError < RuntimeError
      def initialize(registry_file = nil)
        @registry_file = registry_file
      end

      def message
        msg = "Missing 'rules' key"
        msg += " in registry file '#{@registry_file}'" if @registry_file
        msg
      end
    end

    def initialize(rules)
      raise ArgumentError unless rules.is_a?(Enumerable)
      @rules = rules
    end

    attr_reader :rules

    # Loads a registry YAML file
    def self.load_file(registry_file)
      unless File.file?(registry_file)
        raise LoadError, "Registry file '#{registry_file}' does not exist"
      end

      load(YAML.load_file(registry_file), registry_file)
    end

    def self.load(data, registry_file = nil)
      rules =
        if data.is_a?(Hash) && data.key?("rules")
          data["rules"]
        else
          raise ParseError, registry_file
        end

      new(rules ? parse(rules) : [])
    end

    # Parses raw rule hash definitions (like those read from a YAML config) into
    # `Matchd::Rule`s
    #
    # @param rules [Array<Hash>] the raw rule definitions
    # @return [Array<Matchd::Rule>]
    def self.parse(rules)
      rules = rules.is_a?(Array) ? rules : [rules]
      rules.map { |r| Matchd.Rule(r) }
    end

    def each(&block)
      rules.each(&block) if rules
    end

    def valid?
      none? { |r| r.is_a?(Matchd::Rule::Invalid) }
    end
  end
end
