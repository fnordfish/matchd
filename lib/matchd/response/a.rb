# frozen_string_literal: true

class Matchd::Response::A < Matchd::Response
  def initialize(opts)
    super
    @ip = opts.is_a?(Hash) ? opts.fetch("ip") : opts
  end

  attr_reader :ip

  def resource
    Resolv::DNS::Resource::IN::A.new(ip)
  end
end
