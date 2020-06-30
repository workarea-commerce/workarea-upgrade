require 'active_support/all'
require 'action_view/railtie'

require 'workarea'
require 'workarea/storefront'
require 'workarea/admin'

require 'thor'
require 'diffy'
require 'fileutils'
require 'bundler'
require 'rake'

require 'workarea/upgrade/engine'

module Workarea
  module Upgrade
  end
end

require 'workarea/upgrade/diff'
require 'workarea/upgrade/diff/gem_diff'
require 'workarea/upgrade/diff/workarea_file'
require 'workarea/upgrade/diff/current_app'

require 'workarea/upgrade/gemfile'
require 'workarea/upgrade/report'
