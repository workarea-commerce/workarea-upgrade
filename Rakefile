begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'date'
require 'tempfile'

load 'workarea/changelog.rake'

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'workarea/upgrade/version'

desc "Release version #{Workarea::Upgrade::VERSION} of the gem"
task :release do
  host = "https://#{ENV['BUNDLE_GEMS__WEBLINC__COM']}@gems.weblinc.com"

  Rake::Task['workarea:changelog'].execute
  system 'git add CHANGELOG.md'
  system 'git commit -m "Update CHANGELOG"'

  system "git tag -a v#{Workarea::Upgrade::VERSION} -m 'Tagging #{Workarea::Upgrade::VERSION}'"
  system 'git push origin HEAD --follow-tags'

  system "gem build workarea-upgrade.gemspec"
  system "gem push workarea-upgrade-#{Workarea::Upgrade::VERSION}.gem --host #{host}"
  system "rm workarea-upgrade-#{Workarea::Upgrade::VERSION}.gem"
end
