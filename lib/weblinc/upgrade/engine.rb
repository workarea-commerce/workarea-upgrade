module Weblinc
  module Upgrade
    class Engine < ::Rails::Engine
      include Weblinc::Plugin
      isolate_namespace Weblinc::Upgrade

      initializer 'weblinc.upgrade' do
        # configure and customize WebLinc here
      end
    end
  end
end
