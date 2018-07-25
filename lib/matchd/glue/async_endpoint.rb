module Matchd::Glue
  # Wrapper for allowing a more flexible way of defining interfaces for Asyc-*
  class AsyncEndpoint
    # Examples:
    #
    #   # classic triplet array
    #   AsyncIntrface.new([:udp, "0.0.0.0", 53])
    #   AsyncIntrface.new([[:udp, "0.0.0.0", 53], [:tcp, "0.0.0.0", 53]])
    #
    #   # Hash notation
    #   AsyncIntrface.new({"protocol" => :udp, "ip" => "0.0.0.0", "port" => 53})
    #   AsyncIntrface.new({protocol: :udp, ip: "0.0.0.0", port: 53})
    #   AsyncIntrface.new([{protocol: :udp, ip: "0.0.0.0", port: 53}, {protocol: :tcp, ip: "0.0.0.0", port: 53}])
    #
    #   # URI strings
    #   AsyncIntrface.new("udp://0.0.0.0:53")
    #   AsyncIntrface.new(["udp://0.0.0.0:53", "tcp://0.0.0.0:53"])
    def initialize(args)
      endpoints = AsyncEndpoint.parse(args)

      raise ArgementError if !endpoints || endpoints.empty?

      @endpoints = endpoints
    end

    def to_a
      @endpoints
    end

    class << self
      def parse(args)
        val =
          case args
          when Array
            if triplet = parse_array(args)
              [triplet]
            else
              array_args, args = args.partition { |e| e.is_a?(Array) }
              array_args.map { |e| parse_array(e) } + args.flat_map { |e| parse(e) }
            end
          when Hash
            [parse_hash(args)]
          when String
            [parse_uri(args)]
          end

        return nil unless val

        val.compact!

        val.empty? ? nil : val
      end

      # @private
      # parses the classic triplet array notation
      # `[:udp, "0.0.0.0", 53]`
      # and returns just the thing if all data is present
      def parse_array(args)
        args = args.compact
        args if args.length == 3 && %w(udp tcp).include?(args[0].to_s)
      end

      # @private
      # parses a single Hash with named components in string or symbol keys
      # `{"protocol" => :udp, "ip" => "0.0.0.0", "port" => 53}` or
      # `{protocol: :udp, ip: "0.0.0.0", port: 53}`
      # and returns it's triplet notation if all parts are present.
      # there's no additional array wrapping.
      def parse_hash(args)
        protocol = args["protocol"] || args[:protocol]
        ip       = args["ip"]       || args[:ip]
        port     = args["port"]     || args[:port]

        return nil unless protocol && ip && port

        [protocol, ip, port]
      end

      # @private
      # parses a URI string
      # `"udp://0.0.0.0:53"` or `"tcp://0.0.0.0:53"`
      def parse_uri(args)
        uri = URI.parse(args)
        protocol = uri.scheme
        ip       = uri.host
        port     = uri.port

        return nil unless protocol && ip && port

        [protocol, ip, port]
      end
    end
  end
end
