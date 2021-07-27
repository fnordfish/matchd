# frozen_string_literal: true

class Matchd::Response::MX < Matchd::Response
  def initialize(opts)
    super
    @preference = opts.fetch("preference")
    @host = opts.fetch("host")
  end

  attr_reader :preference, :host

  def resource
    Resolv::DNS::Resource::IN::MX.new(
      preference,
      Resolv::DNS::Name.create(host),
    )
  end
end
