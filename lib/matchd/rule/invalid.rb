# frozen_string_literal: true

# Placeholder class for marking keeping invalid Rules around for later
# inspection.
# It overwrited the entire public interface of {Matchd::Rule} to no-operations
class Matchd::Rule::Invalid < Matchd::Rule
  def initialize(options) # rubocop:disable Lint/MissingSuper
    @raw = options
  end
  attr_reader :raw

  # Noop
  # @return [FalseClass] Always returns `false` indecating that processing
  #   shall not stop.
  def visit(*); false end

  # Noop
  # @return [FalseClass] Always returns `false` indecating that this rule
  #   shall not be executed.
  def matches?(*); false end

  # Noop
  # @return [FalseClass] Always returns `false` indecating that processing
  #   shall not stop.
  def call(*); false end
end
