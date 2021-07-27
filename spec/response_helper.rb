# frozen_string_literal: true

require "async/dns"
require "resolv"

RSpec.shared_examples "response resource_options" do |response_data|
  let(:resource_options) do
    {
      "ttl" => 360,
      "section" => "answer",
      "name" => "a.overwritten.name."
    }
  end

  let(:add_options) do
    {
      ttl: 360,
      section: "answer",
      name: "a.overwritten.name."
    }
  end

  it "defaults to empty Hash" do
    subject = described_class.new(response_data)
    expect(subject.resource_options).to be_a(Hash)
  end

  it "transforms resource_options into correct format" do
    subject = described_class.new(response_data.merge(resource_options))
    expect(subject.resource_options).to eq(add_options)
  end

  it "call passes resource_options in correct format" do
    subject = described_class.new(response_data.merge(resource_options))
    expect(transaction).to receive(:add).with(
      [kind_of(Resolv::DNS::Resource)],
      add_options
    )
    subject.call(transaction)
  end
end
