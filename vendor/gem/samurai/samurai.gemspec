# -*- encoding: utf-8 -*-

require File.expand_path('../lib/samurai/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "samurai"
  s.version     = Samurai::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ildo Grings"]
  s.email       = ["ildo@cointrade.cx"]
  s.homepage    = 'https://stratum.io/api'
  s.summary     = %q{Samurai API client}
  s.description = %q{Wrapper for BankToCripto Samurai REST api}
  s.license     = "MIT"

  s.add_dependency "multi_json", "~> 1.0"
  s.add_dependency "httpclient", "~> 2.7"
  s.add_dependency "jruby-openssl" if defined?(JRUBY_VERSION)
  s.add_development_dependency "addressable", "=2.4.0"
  s.add_development_dependency "json", "~> 1.8.3"

  s.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
