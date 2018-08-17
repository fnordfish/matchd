module Matchd
  class Response
    autoload :A,     "matchd/response/a"
    autoload :AAAA,  "matchd/response/aaaa"
    autoload :CNAME, "matchd/response/cname"
    autoload :MX,    "matchd/response/mx"
    autoload :NS,    "matchd/response/ns"
    autoload :PTR,   "matchd/response/ptr"
    autoload :SOA,   "matchd/response/soa"
    autoload :SRV,   "matchd/response/srv"
    autoload :TXT,   "matchd/response/txt"

    NotImplementedError = Class.new(RuntimeError)

    # @param [Hash] options (Mind the string keys!)
    # @option options [Numeric] "ttl" The Time-To-Live of the record (default: `Async::DNS::Transaction::DEFAULT_TTL` = 86400sec = 24h)
    # @option options [String] "name" The absolute DNS name. Default is the question name.
    # @option options [String] "section" The answer section. One of "answer", "additional", "authority" (default: "answer")
    def initialize(options)
      @resource_options = {}

      return unless options.is_a?(Hash)

      @resource_options[:ttl]     = options["ttl"] if options.key?("ttl")
      @resource_options[:name]    = options["name"] if options.key?("name")
      @resource_options[:section] = options["section"] if options.key?("section")
    end

    attr_reader :resource_options

    def resource
      raise NotImplementedError
    end

    def call(transaction)
      transaction.add([resource], resource_options)
    end

    def valid?
      # TODO: this needs to be more suffisticated
      resource && true
    rescue ArgumentError
      false
    end

    module Factory
      # Creates new instances of a {Matchd::Response} subclass. Which class is being used
      # is defines via the {respond} or {fallback_resource_class} parameters.
      #
      # @param respond [Array<Hash>|Hash] One or multiple response configurations (See subclasses)
      # @param fallback_resource_class [Array[String]|String] One or multiple ressource class names (like `"A"`, `"AAAA"`, `"MX"` etc)
      #   defining which Resource subclass is being used if the {respond} doesn't include a `"resource_class"` configuration
      #
      # @return [Array<Matchd::Response>] Instances of {Matchd::Response} subclasses.
      def Response(respond, fallback_resource_class) # rubocop:disable Naming/MethodName
        respond = [respond] unless respond.is_a?(Array) # don't convert Hash to Array
        respond.flat_map do |r|
          resource_class =
            if r.is_a?(Hash)
              r.fetch("resource_class", fallback_resource_class)
            else
              fallback_resource_class
            end

          raise ArgumentError, "Missing resource_class for Response" unless resource_class

          Array(resource_class).map { |klass| Matchd::Response.const_get(klass.upcase).new(r) }
        end
      end
    end
  end
end
