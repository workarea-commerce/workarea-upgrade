require 'weblinc'
require 'weblinc/store_front'
require 'weblinc/admin'

require 'thor'
require 'diffy'
require 'fileutils'
require 'bundler'

require 'weblinc/upgrade/engine'

module Weblinc
  module Upgrade
  end
end

require 'weblinc/upgrade/migration'
require 'weblinc/upgrade/migration/v2'

require 'weblinc/upgrade/diff'
require 'weblinc/upgrade/diff/weblinc_file'
require 'weblinc/upgrade/diff/current_app'

require 'weblinc/upgrade/report_card'
