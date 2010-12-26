# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "em-battleye/version"

Gem::Specification.new do |s|
  s.name        = "em-battleye"
  s.version     = EventMachine::BattlEye::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Erik Gävert"]
  s.email       = ["erik@gavert.net"]
  s.homepage    = ""
  s.summary     = %q{EventMachine BattlEye rcon client}
  s.description = %q{An BattlEye rcon client implementation using EventMachine}

  s.rubyforge_project = "em-battleye"
  s.add_dependency "eventmachine"
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
