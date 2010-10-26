# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hammer/version"

Gem::Specification.new do |s|

  s.name          = "hammer"
  s.version       = Hammer::VERSION.dup
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Mike Williams"]
  s.email         = "mdub@dogbiscuit.org"
  s.homepage      = "http://github.com/mdub/hammer"
  s.summary       = %q{TODO: Write a gem summary}
  s.description   = %q{TODO: Write a gem description}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

end
