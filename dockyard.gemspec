# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dockyard/version'

Gem::Specification.new do |spec|
  spec.name          = "dockyard"
  spec.version       = Dockyard::VERSION
  spec.authors       = ["Joel McCracken"]
  spec.email         = ["mccracken.joel@gmail.com"]

  spec.summary       = %q{A Ruby API for Docker}
  spec.description   = %q{A Ruby API for Docker}
  spec.homepage      = "https://github.com/joelmccracken/dockyard"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end

# Local Variables:
# mode: ruby
# End:
