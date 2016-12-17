# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rollbar/dumps/version'

Gem::Specification.new do |spec|
  spec.name          = "rollbar-dumps"
  spec.version       = Rollbar::Dumps::VERSION
  spec.authors       = ["Jon de Andres"]
  spec.email         = ["jon@rollbar.com"]

  spec.summary       = %q{Rollbar notifier for core dumps}
  spec.description   = %q{Rollbar notifier for core dumps}
  spec.homepage      = "https://github.com/jondeandres/rollbar-dumps"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
