class Matchd::Response::CNAME < Matchd::Response
  def initialize(opts)
    super
    @alias_name = opts.is_a?(Hash) ? opts.fetch("alias") : opts
  end

  attr_reader :alias_name

  def resource
    Resolv::DNS::Resource::IN::CNAME.new(Resolv::DNS::Name.create(alias_name))
  end
end
