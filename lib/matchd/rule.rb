require "resolv"

module Matchd
  class Rule
    autoload :Append,      "matchd/rule/append"
    autoload :Fail,        "matchd/rule/fail"
    autoload :Invalid,     "matchd/rule/invalid"
    autoload :Passthrough, "matchd/rule/passthrough"
    autoload :Respond,     "matchd/rule/respond"

    REGEXP_MATCHER = %r{\A/(.*)/([mix]*)\Z}m

    REGEXP_OPTIONS = {
      "m" => Regexp::MULTILINE,
      "i" => Regexp::IGNORECASE,
      "x" => Regexp::EXTENDED
    }.freeze

    # parses a Regexp lookalike String into Regexp or returns the String
    def self.parse_match(name)
      if name.is_a?(Regexp)
        name
      elsif (r = name.match(REGEXP_MATCHER))
        regexp_opts = r[2].each_char.reduce(0) { |o, c| o |= REGEXP_OPTIONS[c] } # rubocop:disable Lint/UselessAssignment # No, it's not!
        Regexp.new(r[1], regexp_opts)
      else
        name
      end
    end

    def self.parse_resource_class(resource_class)
      resource_class.map do |klass|
        case klass
        when ::Resolv::DNS::Resource then klass
        when String, Symbol then ::Resolv::DNS::Resource::IN.const_get(klass.upcase)
        end
      end
    end

    NotImplementedError = Class.new(RuntimeError)

    def initialize(options)
      @raw = options
      @match_name = options.fetch("match")
      @match_resource_classes = Array(options.fetch("resource_class"))
    end
    attr_reader :raw

    # Implements the rule logic formulating the DNS response to a query.
    # It's return value signals whether this rule was a successful match (in the
    # sense of the rule) and evaluating later rules shall be stopped.
    #
    # @note You should not need to call this method directly, use {#call} instead .
    #
    # @abstract This method needs to be implemented by subclasses.
    #
    # @param server [Matchd::Server]
    # @param name [String] The query name
    # @param resource_class [Resolv::DNS::Resource] The query IN ressource
    # @param transaction [Async::DNS::Transaction]
    # @return [TrueClass|FalseClass] Whether further processing shall stop
    def visit!(_server, _name, _resource_class, _transaction)
      raise NotImplementedError
    end

    # Checks if this rule matches a DNS query (name and ressource class).
    # @return [TrueClass|FalseClass]
    def matches?(query_name, query_resource_class)
      name_for_match === query_name && # rubocop:disable Style/CaseEquality #  This does string equality and Regexp matching at the same time
        resource_classes_for_match.include?(query_resource_class)
    end

    # This is the main interface for executing rules.
    # It tests if this rule matches by calling {#matches?} and runs it by
    # calling {#visit!}
    #
    # @param server [Matchd::Server]
    # @param name [String] The query name
    # @param resource_class [Resolv::DNS::Resource] The query IN ressource
    # @param transaction [Async::DNS::Transaction]
    # @return [TrueClass|FalseClass] Whether further processing shall stop
    def call(server, name, resource_class, transaction)
      return false unless matches?(name, resource_class)

      visit!(server, name, resource_class, transaction)
    end

    # @private
    def match_name
      @_match_name ||= self.class.parse_match(@match_name)
    end

    # @private
    def match_resource_classes
      @_match_resource_classes ||= self.class.parse_resource_class(@match_resource_classes)
    end

    module Factory
      def Rule(data) # rubocop:disable Naming/MethodName
        return Rule::Invalid.new(data) unless data.is_a?(Hash)

        if data["respond"]
          Rule::Respond.new(data)
        elsif data["append_question"]
          Rule::Append.new(data)
        elsif data["passthrough"]
          Rule::Passthrough.new(data)
        elsif data["fail"]
          Rule::Fail.new(data)
        else
          Rule::Invalid.new(data)
        end
      end
    end
  end
end
