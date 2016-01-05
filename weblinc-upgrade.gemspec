$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "weblinc/upgrade/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "weblinc-upgrade"
  s.version     = Weblinc::Upgrade::VERSION
  s.authors     = ["Ben Crouse"]
  s.email       = ["bcrouse@weblinc.com"]
  s.homepage    = 'http://www.weblinc.com'
  s.summary     = 'Weblinc upgrade tools'
  s.description = 'Upgrade tools for the Weblinc ecommerce system'
  s.files = `git ls-files`.split("\n")

  s.required_ruby_version = '>= 2.0.0'
  s.add_dependency 'weblinc', '~> 2.0.2'
end
