require 'weblinc'
require 'weblinc/store_front'
require 'weblinc/admin'

require 'diffy'
require 'fileutils'
require 'byebug'

require 'weblinc/upgrade/engine'

module Weblinc
  module Upgrade
  end
end

require 'weblinc/upgrade/migration'
require 'weblinc/upgrade/migration/v2'

require 'weblinc/upgrade/diff'
