class Matchd::Response::NS < Matchd::Response
  def initialize(opts)
    super
    @host = opts.is_a?(Hash) ? opts.fetch("host") : opts
  end

  attr_reader :host

  def resource
    Resolv::DNS::Resource::IN::NS.new(Resolv::DNS::Name.create(host))
  end
end
