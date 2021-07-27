# frozen_string_literal: true

class Matchd::Response::TXT < Matchd::Response
  def initialize(opts)
    super
    @txt = opts.is_a?(Hash) ? opts.fetch("txt") : opts
  end

  attr_reader :txt

  def resource
    Resolv::DNS::Resource::IN::TXT.new(txt)
  end
end
