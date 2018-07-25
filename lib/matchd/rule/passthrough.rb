require "async/dns"
require "async/dns/system"

class Matchd::Rule::Passthrough < Matchd::Rule
  # @param [Hash] options
  # @option options [Array<Array>|Array<Hash>|Async::DNS::Resolver] "resolver" List of passthrough DNS servers. See `Matchd::Glue::AsyncEndpoint` for more formats.
  def initialize(options)
    super
    opts = options.fetch("passthrough")

    @passthrough_options = {}

    if opts.is_a?(Hash) && options.key?("resolver")
      @resolver = opts["resolver"]
      @passthrough_options[:force] = opts["force"] if options.key?("force")
      @passthrough_options[:name] = opts["name"] if options.key?("name")
    else
      @resolver = opts
    end
  end

  attr_reader :resolver, :passthrough_options

  def visit!(server, _name, _resource_class, transaction)
    passthrough_resolver =
      case resolver
      when Async::DNS::Resolver
        resolver
      when "system", :system, nil
        Async::DNS::Resolver.new(Async::DNS::System.nameservers)
      else
        Async::DNS::Resolver.new(Matchd::Glue::AsyncEndpoint.parse(resolver))
      end

    transaction.passthrough!(passthrough_resolver, passthrough_options) do |response|
      server.logger.debug ";; Passthrough to System resolver"
      server.logger.debug ";; Question"
      server.logger.debug(*response.question.map { |q, r| "#{q}\t#{r}" })
      server.logger.debug ";; Answer"
      if response.answer.any?
        response.answer.each do |name_in_answer, ttl, record|
          server.logger.debug "#{name_in_answer}\t#{ttl}\t#{record.class}\t#{record.name}"
        end
      else
        server.logger.debug ";; Empty"
      end
    end
  end
end
