# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'goatos/version'

Gem::Specification.new do |spec|
  spec.name          = "et"
  spec.version       = GoatOS::VERSION
  spec.authors       = ["Ranjib Dey"]
  spec.email         = ["ranjib@linux.com"]
  spec.description   = %q{Build and manage LXC using Chef}
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/medhamesh/lxcos"
  spec.license       = "Apache 2"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "mixlib-log"
  spec.add_dependency "chef"
  spec.add_dependency "chef-zero"
  spec.add_dependency "berkshelf"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
