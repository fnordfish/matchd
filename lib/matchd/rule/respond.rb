# frozen_string_literal: true

class Matchd::Rule::Respond < Matchd::Rule
  def initialize(options)
    super
    @responses = options.fetch("respond")
  end

  attr_reader :responses

  def visit!(_server, _name, _resource_class, transaction)
    # Using the original Rule's resource_classes definition as a fallback, if
    # the response doesn't configure one.
    Matchd.Response(responses, @resource_classes).each do |resp|
      resp.call(transaction)
    end
  end
end
