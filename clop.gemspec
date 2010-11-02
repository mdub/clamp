# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "clop/version"

DESCRIPTION = <<EOF
Clop makes provides an object-model for command-line utilities.  
It handles parsing of command-line options, and generation of usage help.
EOF

Gem::Specification.new do |s|

  s.name          = "clop"
  s.version       = Clop::VERSION.dup
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Mike Williams"]
  s.email         = "mdub@dogbiscuit.org"
  s.homepage      = "http://github.com/mdub/clop"
  s.summary       = %q{a minimal framework for command-line utilities}
  s.description   = DESCRIPTION

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

end
