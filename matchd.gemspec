require File.expand_path('lib/matchd/version', __dir__)

Gem::Specification.new do |spec|
  spec.name          = "matchd"
  spec.version       = Matchd::VERSION
  spec.authors       = ["Robert Schulze"]
  spec.email         = ["robert@dotless.de"]
  spec.license       = "MLP-2.0"

  spec.summary       = 'A Async::DNS daemon with expanded yaml configuration.'
  spec.description   = <<-DESC
    Let's you use Async::DNS as a server daemon and configure it using yaml files. No writing ruby code required.
  DESC
  spec.homepage      = "https://github.com/fnordfish/matchd"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "async-dns", "~> 1.2.0"
  spec.add_runtime_dependency "daemons"
  spec.add_runtime_dependency "dry-configurable", "~> 0.7.0"
  spec.add_runtime_dependency "thor", "~> 0.20.0"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
