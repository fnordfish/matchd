class Matchd::Rule::Append < Matchd::Rule
  def initialize(options)
    super
    opts = options.fetch("append_question")

    @transaction_options = Matchd::Helpers.extract_options(%w(ttl name section), options)
    @append_questions =
      if opts.is_a?(Hash)
        Array(opts.fetch("resource_class"))
      else
        Array(opts)
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
