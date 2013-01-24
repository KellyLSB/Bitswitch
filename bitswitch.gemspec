# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bitswitch/version'

Gem::Specification.new do |gem|
  gem.name          = "bitswitch"
  gem.version       = KellyLSB::BitSwitch::VERSION
  gem.authors       = ["Kelly Becker"]
  gem.email         = ["kellylsbkr@gmail.com"]
  gem.description   = "Have you ever wanted to store multiple true/false values in your database, but annoyed with how many fields your tables have, then BitSwitcher is good for you. By assigning a bit for each true/false you can store all your fields in one integer."
  gem.summary       = "Bitswitch lets you store multiple true/false values in an integer using boolean math."
  gem.homepage      = "http://kellybecker.me"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
