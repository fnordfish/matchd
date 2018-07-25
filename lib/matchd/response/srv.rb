class Matchd::Response::SRV < Matchd::Response
  def initialize(opts)
    super
    @target = opts.fetch("target")
    @priority = opts.fetch("priority")
    @weight = opts.fetch("weight")
    @port = opts.fetch("port")
  end

  attr_reader :target, :priority, :weight, :port

  def resource
    Resolv::DNS::Resource::IN::SRV.new(
      priority,
      weight,
      port,
      target
    )
  end
end
