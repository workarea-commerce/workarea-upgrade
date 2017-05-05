require 'active_support/core_ext/module/delegation'

begin
  require 'workarea'
  require 'workarea/storefront'
  require 'workarea/admin'
  WORKAREA_ALIASED = false
rescue LoadError
  require 'weblinc'
  require 'weblinc/store_front'
  require 'weblinc/admin'

  Workarea = Weblinc
  WORKAREA_ALIASED = true
end

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

require 'workarea/upgrade/migration'
require 'workarea/upgrade/migration/v2'
require 'workarea/upgrade/migration/v3'

require 'workarea/upgrade/diff'
require 'workarea/upgrade/diff/gem_diff'
require 'workarea/upgrade/diff/workarea_file'
require 'workarea/upgrade/diff/current_app'

require 'workarea/upgrade/report_card'
