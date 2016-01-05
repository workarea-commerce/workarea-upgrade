WebLinc Upgrade
================================================================================

Upgrade plugin for the WebLinc platform.

Getting Started
--------------------------------------------------------------------------------

This gem contains a rails engine that must be mounted onto a host Rails application.

You must have access to a WebLinc gems server to use this gem. Add your gems server credentials to Bundler:

    bundle config gems.weblinc.com my_username:my_password

Or set the appropriate environment variable in a shell startup file:

    export BUNDLE_GEMS__WEBLINC__COM='my_username:my_password'

Then add the gem to your application's Gemfile specifying the source:

    # ...
    gem 'weblinc-upgrade', source: 'https://gems.weblinc.com'
    # ...

Or use a source block:

    # ...
    source 'https://gems.weblinc.com' do
      gem 'weblinc-upgrade'
    end
    # ...

Update your application's bundle.

    cd path/to/application
    bundle

WebLinc Platform Documentation
--------------------------------------------------------------------------------

See [http://guides.weblinc.com](http://guides.weblinc.com) for WebLinc platform documentation.

Copyright & Licensing
--------------------------------------------------------------------------------

Copyright WebLinc 2015. All rights reserved.

For licensing, contact sales@weblinc.com.
