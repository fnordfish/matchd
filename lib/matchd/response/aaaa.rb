# frozen_string_literal: true

class Matchd::Response::AAAA < Matchd::Response::A
  def resource
    Resolv::DNS::Resource::IN::AAAA.new(ip)
  end
end
