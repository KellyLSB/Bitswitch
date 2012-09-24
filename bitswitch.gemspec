# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bitswitch/version'

Gem::Specification.new do |gem|
  gem.name          = "bitswitch"
  gem.version       = Bitswitch::VERSION
  gem.authors       = ["Kelly Becker"]
  gem.email         = ["kellylsbkr@gmail.com"]
  gem.description   = "Bitswitch is a gem designed to make storing multiple true false values easier"
  gem.summary       = "Soon..."
  gem.homepage      = "http://kellybecker.me"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
