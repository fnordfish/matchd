require "time"

class Matchd::Response::SOA < Matchd::Response
  def initialize(opts)
    super
    @mname = opts.fetch("mname")
    @rname = opts.fetch("rname")
    @serial = opts.fetch("serial")
    @refresh_time = opts.fetch("refresh")
    @retry_time = opts.fetch("retry")
    @expire_time = opts.fetch("expire")
    @minimum_ttl = opts.fetch("minimum_ttl")
  end

  attr_reader :mname, :rname, :serial, :refresh_time, :retry_time, :expire_time, :minimum_ttl

  def resource
    Resolv::DNS::Resource::IN::SOA.new(
      Resolv::DNS::Name.create(mname),
      Resolv::DNS::Name.create(rname),
      serial,
      refresh_time,
      retry_time,
      expire_time,
      minimum_ttl
    )
  end
end
