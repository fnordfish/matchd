RSpec.describe Matchd::Config do
  it { expect(described_class).to be_a(Dry::Configurable) }
end
