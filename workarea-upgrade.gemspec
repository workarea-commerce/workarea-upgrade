$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "workarea/upgrade/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "workarea-upgrade"
  s.version     = Workarea::Upgrade::VERSION
  s.authors     = ["Ben Crouse"]
  s.email       = ["bcrouse@weblinc.com"]
  s.homepage    = 'http://www.workarea.com'
  s.summary     = 'Workarea upgrade tools'
  s.description = 'Upgrade tools for the Workarea commerce system'
  s.files       = `git ls-files`.split("\n")
  s.bindir      = 'exe'
  s.executable  = 'workarea_upgrade'

  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency 'diffy', '~> 3.1.0'
  s.add_dependency 'bundler'

  s.add_development_dependency 'rake'
end
