class Matchd::Rule::Fail < Matchd::Rule
  def initialize(options)
    super
    @fail = options.fetch("fail")
  end

  def visit!(_server, _name, _resource_class, transaction)
    transaction.fail!(rcode)
  end

  def rcode
    @rcode ||=
      case @fail
      when Symbol, String then Resolv::DNS::RCode.const_get(@fail)
      else @fail
      end
  end
end
