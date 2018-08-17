module Matchd::Glue
  # Wrapper for allowing a more flexible way of defining interfaces for Asyc-*
  module AsyncEndpoint
    class << self
      # Examples:
      #
      #   # classic triplet array
      #   AsyncIntrface.parse([:udp, "0.0.0.0", 53])
      #   AsyncIntrface.parse([[:udp, "0.0.0.0", 53], [:tcp, "0.0.0.0", 53]])
      #
      #   # Hash notation
      #   AsyncIntrface.parse({"protocol" => :udp, "ip" => "0.0.0.0", "port" => 53})
      #   AsyncIntrface.parse({protocol: :udp, ip: "0.0.0.0", port: 53})
      #   AsyncIntrface.parse([{protocol: :udp, ip: "0.0.0.0", port: 53}, {protocol: :tcp, ip: "0.0.0.0", port: 53}])
      #
      #   # URI strings
      #   AsyncIntrface.parse("udp://0.0.0.0:53")
      #   AsyncIntrface.parse(["udp://0.0.0.0:53", "tcp://0.0.0.0:53"])
      def parse(args)
        val =
          case args
          when Array
            if triplet = parse_array(args)
              [triplet]
            else
              args.flat_map { |e| parse(e) }
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

      # Supported DNS protocols
      PROTOCOLS = %w(udp tcp).freeze

      # Default port used when the port is omitted in Hash or String notation.
      DEFAULT_PORT = 53

      private

      # @private
      # parses the classic triplet array notation
      # `[:udp, "0.0.0.0", 53]`
      # and returns just the thing if all data is present.
      # To ensure proper triplet detection, all values are required. No port default.
      def parse_array(args)
        protocol, ip, port = args

        return nil unless PROTOCOLS.include?(protocol.to_s) && ip && port

        [protocol.to_sym, ip, port]
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
        port     = args["port"]     || args[:port] || DEFAULT_PORT

        return nil unless PROTOCOLS.include?(protocol.to_s) && ip

        [protocol.to_sym, ip, port]
      end

      # @private
      # parses a URI string
      # `"udp://0.0.0.0:53"` or `"tcp://0.0.0.0:53"`
      def parse_uri(args)
        uri = URI.parse(args)
        protocol = uri.scheme
        ip       = uri.host
        port     = uri.port || DEFAULT_PORT

        return nil unless PROTOCOLS.include?(protocol.to_s) && ip

        [protocol.to_sym, ip, port]
      end
    end
  end
end
