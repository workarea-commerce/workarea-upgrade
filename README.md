Workarea Upgrade
================================================================================

Workarea Upgrade makes it easier to upgrade your application to use newer
versions of Workarea and Workarea plugins. 

This plugin should be used to take each patch, minor, or major version of the
Workarea platform and/or any of its plugins.

Use this plugin to:

* View a report to help you determine the effort required to upgrade.
* Migrate your database.
* Diff any two Workarea versions (back to version 0.8.0) and filter the
results to show only the changes affecting your application.
* View lists of files added and removed between versions of Workarea.


Step 1: Install the Plugin
--------------------------------------------------------------------------------

Add the plugin to your application's Gemfile:

    gem 'workarea-upgrade', source: 'https://gems.weblinc.com', group: 'development'

**NOTE:** If you are using `weblinc-modernizr-rails`, remove it from
your Gemfile. This will cause a conflict in the upgrade engine, and is
not required for Workarea v3.x.

Update your bundle. Use `bundle update` to get the latest version:

    cd path/to/your_app
    bundle update workarea-upgrade


Step 2: View Help
--------------------------------------------------------------------------------

Run `workarea_upgrade` without arguments to view help:

    cd path/to/your_app
    bundle exec workarea_upgrade

Use `help` to get detailed help for a specific command:

    cd path/to/your_app
    bundle exec workarea_upgrade help report

Step 3: Install Target Gems
--------------------------------------------------------------------------------

Install each Gem that you will be upgrading to.

    gem install example-gem -v UPGRADE_VERSION

Step 4: View Report & Begin Upgrade
--------------------------------------------------------------------------------

Start by viewing an upgrade report. The report will summarize the work required
to upgrade to specific versions of Workarea and Workarea plugins.

The report will suggest next steps for your upgrade.

    bundle exec workarea_upgrade report 3.4.1

Step 5: Migrate Your Database
--------------------------------------------------------------------------------

If upgrading to a major or minor version of Workarea, a database migration may
be available.

First, update your bundle to use the newer version of Workarea and use the tools
described above to help achieve compatibility with the newer version.

Then run the database migration:

    cd path/to/your_app
    bin/rake workarea:upgrade:migrate

[See more information on migrating from version 2 to 3](docs/guides/migrating-a-database-from-v2-to-v3.html)

Tips & Recommendations
--------------------------------------------------------------------------------

## Strive to stay up to date

New versions of the Workarea platform and its plugins are being released every
two weeks, on average. Taking these patches as they are released is paramount
to lessening the cognitive and financial impact of a larger upgrade later down
the road.

Some patches even contain very important security updates from upstream gems 
on which the platform depends.

There should be very little reason not to take any and all patch versions. By
design, these releases represent the least amount of change and greatly increase
the stability of your project.

If you wish to receive an announcement via email each time a release is made,
please email <choward@workarea.com> to be added to the release announcement
mailing list.

## Upgrading out of date projects

For many reasons projects become out of date. If you are trying to upgrade your 
project to the latest patch in your current minor version, you can do so using 
the Upgrade Plugin as well.

This step is especially important when trying to upgrade your project beyond
your current minor version. 

Imagine the following scenario:

* Your project is on version `3.0.5`
* The latest patch on the v3.0 minor is `3.0.20`
* The latest patch on the v3.1 minor is `3.1.25`
* The absolute latest version of the platform is `3.2.30`
* You want your project to be on the absolute latest version of the platform

This means that you're going to have to upgrade from the v3.0 minor through the 
v3.1 minor to the v3.2 minor.

__Note:__ The upgrade should be performed in a branch separate from your main
development branch so that you can push after each step. This will allow the CI
server to pick up the changes and run the test suite on each step. Manual
testing is also suggested to make sure no visual bugs are introduced.

Using the example above, the prescribed method for upgrading would be to use the
Upgrade Plugin to upgrade your project from:

1. `3.0.5` to `3.0.20`
1. `3.0.20` to `3.1.25`
1. `3.1.25` to `3.2.30`

This will yield diffs containing the least amount of change possible, due to the 
way the product's patches are handled internally.

## Diff Results

The visual diffs that are produced by this plugin apply to any overridden or 
decorated file within your project. The visual diff _displays changes between
the two versions of the platform file only_. This means that you, as the
developer, should have a general awareness of why the file in your project was
overridden and how it was customized. This just means that the diff shows you
what has changed at the platform level and its up to you, the developer, to 
apply those changes to your project accordingly.

All diffs should be regarded as important with the exception of SCSS changes. 
Since there will rarely be a bug introduced in the Stylesheets that will be 
applicable to your project, these files can be generally disregarded during the
upgrade. Most project heavily customize the styles to satisfy the needs of the 
client and stray far away from the platform's default look-and-feel as a result.

## Upgrading Theme Plugins

Though themes are technically plugins, they are a special type of plugin that 
overrides views the same way an app would. Because of this fact they can also
be upgraded in the same way as an app.

However, due to the permissive way plugins depend on the `workarea` gem, before 
you begin the upgrade process, you must first set your dependency within the 
theme's gemspec more pessimistically. 

As an example, version 1.0.0 of the Clifton theme was created during Workarea's
v3.3 release life cycle, which means that the views overridden into this theme
closely resemble those released in v3.3.0. Following this example, we are trying
to release this theme's next minor version, 1.1.0, which will be compatible with 
Workarea 3.4.0.

Before completing Step 1, above, by changing the Workarea dependency within the 
plugin's gemfile from `~> 3.x` to `3.3.0` before running a `bundle update`, the
upgrade then is allowed to function properly as though we are upgrading a real
app.

Copyright & Licensing
--------------------------------------------------------------------------------

Copyright Weblinc 2017. All rights reserved.

For licensing, contact sales@workarea.com.
