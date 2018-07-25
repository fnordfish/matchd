require "async/dns"

module Matchd
  class Server < Async::DNS::Server
    # @param registry [Matchd::Registry] A rules registry
    # @param listen [Array] On which interfaces to listen (`[[<protocol>, <ip>, <port>], ...]`). See `Matchd::Glue::AsyncEndpoint` for more formats.
    # @param [Hash] opts
    # @option opts [Array|Async::DNS::Resolver] :resolver The upstream resolvers (`[[<protocol>, <ip>, <port>], ...]`). See `Matchd::Glue::AsyncEndpoint` for more formats. (default: `Async::DNS::System.nameservers`)
    def initialize(registry, listen, options = {})
      @registry = registry
      @resolver = options.delete(:resolver)

      listen = Matchd::Glue::AsyncEndpoint.parse(listen)

      super(listen, options)
    end

    attr_reader :registry, :resolver

    def process(name, resource_class, transaction)
      found = registry.any? do |rule|
        rule.call(self, name, resource_class, transaction)
      end

      passthrough!(name, resource_class, transaction) unless found
    end

    def passthrough!(name, resource_class, transaction)
      Matchd::Rule::Passthrough.new(
        "passthrough" => resolver,
        "match" => name,
        "resource_class" => resource_class
      ).visit!(self, name, resource_class, transaction)
    end
  end
end
