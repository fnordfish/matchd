require "async/dns"

module Matchd
  # Specific implementation of the {Async::DNS::Server} using a list of rules to determine it's response
  #
  # Rules will get {#call}'ed in order until the first one matches (returns truthy).
  # If none matches, a default {Matchd::Rule::Passthrough} will get executed forwarding the query to the resolver
  # defined via the `:resolver` option.
  class Server < Async::DNS::Server
    # @param rules [Matchd::Registry|Array<Matchd.Rule>] A rules registry
    # @param listen [Array] On which interfaces to listen (`[[<protocol>, <ip>, <port>], ...]`). See `Matchd::Glue::AsyncEndpoint` for more formats.
    # @param [Hash] options
    # @option options [Array|Async::DNS::Resolver] :resolver The upstream resolvers (`[[<protocol>, <ip>, <port>], ...]`). See `Matchd::Glue::AsyncEndpoint` for more formats. (default: `Async::DNS::System.nameservers`)
    # @option options [TrueClass|FalseClass] :forced_passthtough The default Passthrough rule's `force` option
    def initialize(rules, listen, options = {})
      @rules = rules
      @resolver = options.delete(:resolver)
      @forced_passthtough = options.delete(:forced_passthtough) { true }

      listen = Matchd::Glue::AsyncEndpoint.parse(listen)

      super(listen, *options)
    end

    attr_reader :rules, :resolver

    def process(name, resource_class, transaction)
      found = rules.any? do |rule|
        rule.call(self, name, resource_class, transaction)
      end

      passthrough!(name, resource_class, transaction) unless found
    end

    def passthrough!(name, resource_class, transaction)
      Matchd::Rule::Passthrough.new(
        "passthrough" => resolver,
        "match" => name,
        "resource_class" => resource_class,
        "force" => @forced_passthtough
      ).visit!(self, name, resource_class, transaction)
    end
  end
end
