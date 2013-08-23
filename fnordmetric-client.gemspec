# -*- encoding: utf-8 -*-
require File.expand_path('../lib/fnordmetric-client/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ilya Averyanov"]
  gem.email         = ["av@fun-box.ru"]
  gem.description   = %q{Standalone client for fnordmetric}
  gem.summary       = %q{Standalone and a safer client for fnordmetric https://github.com/paulasmuth/fnordmetric}
  gem.homepage      = "https://github.com/savonarola/fnordmetric-client"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fnordmetric-client"
  gem.require_paths = ["lib"]
  gem.version       = FnordmetricClient::VERSION
  gem.license       = 'MIT'

  gem.add_runtime_dependency('json')

  gem.add_development_dependency('rake')
  gem.add_development_dependency('mock_redis')
  gem.add_development_dependency('rspec')
  gem.add_development_dependency('timecop')
end
