require "bundler/setup"
require "simplecov"
SimpleCov.start

require "matchd"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random
  Kernel.srand config.seed

  def fixture_path(*file_path)
    File.join(File.dirname(__FILE__), "fixtures", *file_path)
  end
end
