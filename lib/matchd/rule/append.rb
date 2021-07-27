# frozen_string_literal: true

class Matchd::Rule::Append < Matchd::Rule
  def initialize(options)
    super
    opts = options.fetch("append_question")

    if opts.is_a?(Hash)
      @append_questions = Array(opts.fetch("resource_class"))
      @transaction_options = Matchd::Helpers.extract_options(%w(ttl name section), opts)
    else
      @append_questions = Array(opts)
      @transaction_options = {}
    end
  end

  attr_reader :append_questions, :transaction_options

  def visit!(_server, _name, _resource_class, transaction)
    transaction.append_question!
    Matchd::Rule.parse_resource_class(append_questions).each do |append_resource_class|
      transaction.append!(transaction.name, append_resource_class, transaction_options)
    end
  end
end
