# -*- encoding: utf-8 -*-
require File.expand_path('../lib/amazon/aws/simple_version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["kimoto"]
  gem.email         = ["sub+peerler@gmail.com"]
  gem.description   = %q{Simple Wrapper for ruby-aaws}
  gem.summary       = %q{Simple Wrapper for ruby-aaws}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ruby-aaws-simple"
  gem.require_paths = ["lib"]
  gem.version       = Amazon::AWS::Simple::VERSION
end
