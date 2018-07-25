class Matchd::Rule::Respond < Matchd::Rule
  def initialize(options)
    super
    @responses = options.fetch("respond")
  end

  attr_reader :responses

  def visit!(_server, _name, _resource_class, transaction)
    Matchd.Response(responses, match_resource_classes).each do |resp|
      resp.call(transaction)
    end
  end
end
