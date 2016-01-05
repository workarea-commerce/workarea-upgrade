begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'weblinc/upgrade/version'

desc "Release version #{Weblinc::Upgrade::VERSION} of the gem"
task :release do
  host = "https://#{ENV['BUNDLE_GEMS__WEBLINC__COM']}@gems.weblinc.com"

  system "git tag -a v#{Weblinc::Upgrade::VERSION} -m 'Tagging #{Weblinc::Upgrade::VERSION}'"
  system 'git push --tags'

  system "gem build weblinc-upgrade.gemspec"
  system "gem push weblinc-upgrade-#{Weblinc::Upgrade::VERSION}.gem --host #{host}"
  system "rm weblinc-upgrade-#{Weblinc::Upgrade::VERSION}.gem"
end


