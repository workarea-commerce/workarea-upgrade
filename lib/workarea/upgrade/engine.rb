module Workarea
  module Upgrade
    class Engine < ::Rails::Engine
      include Workarea::Plugin
      isolate_namespace Workarea::Upgrade

      initializer 'workarea.upgrade' do
        # configure and customize Workarea here
      end
    end
  end
end
