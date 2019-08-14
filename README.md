# Workarea Upgrade 

A plugin for upgrading to newer versions of Workarea and its plugins.

## Overview

* Used for upgrading to new patches, minors, or majors
* View a report of the complexity of the upgrade
* Diff code change between any two version of Workarea in the v3 series 
* See results relevant to the overridden or decorated files in your application

## Features

* __Command Line Interface__
  
  The features of this plugin are accessibile by invoking the `workarea_upgrade`
  command. After installing this plugin run `bundle exec workarea_upgrade help`
  for an overview of which commands are available to you.

* __Upgrade Preparation__
  
  The Upgrade plugin uses the differences found between your `Gemfile` and a 
  `Gemfile.next` file present in your application's root directory to generate
  its reporting and diffing functionality. You can create and manage this 
  `Gemfile.next` yourself or use the `prepare` task to automate its creation.

* __Reporting__

  To get an idea of how complex your upgrade will be the Upgrade gem provides
  a `report` task which shows basic statistics about the amount of change the 
  Workarea platform has undergone between versions listed in your `Gemfile` and
  `Gemfile.next`. These statistics should give you a general idea of how much 
  work may be required to perform the upgrade.

* __Diffing__
 
 The Upgrade plugin will display a full diff of changes made to Workarea as they
 pertain to your application. If you've overridden or decorated any core 
 Workarea file or a file from a Workarea plugin the Upgrade gem will show you
 the change to that file between the versions specified in your `Gemfile` and 
 `Gemfile.next`. Use this information to upgrade your application accordingly.

## Getting Started

### Installation

Add the plugin to your application's `Gemfile`:

    group :development do
      gem 'workarea-upgrade', '>= 3.0.0', source: 'https://gems.workarea.com'
    end

Update your bundle. Use `bundle update` to get the latest version:

    cd path/to/your_app
    bundle update workarea-upgrade

### View Help

Run `workarea_upgrade help` for an overview of the commands and what they do:

    bundle exec workarea_upgrade help

Run `workarea_upgrade help TASK` to get more information about a given task:

    bundle exec workarea_upgrade help report

### Create a Gemfile.next

The Upgrade plugin uses a `Gemfile.next` file in your application's root
directory to determine the versions you wish to upgrade to.

This file may be created manually, by copying and modifying your `Gemfile` as a
`Gemfile.next` file, or automatically, by running:

    bundle exec workarea_upgrade

This will drop you into a wizard that will determine the newest versions of each
of your Workarea gems and iterate over them, allowing you to add, remove, or 
modify the version of each gem found. These choices are used to generate the 
`Gemfile.next` file for you automatically. 

Once the process is complete the `Gemfile.next` will be tested for installation.
If it fails installation you will be given instructions on how to fix it
manually until it is in an installable state.

### View Report

Once the `Gemfile.next` file is installable, you may get an idea of the
complexity of your upgrade by viewing the report:

    bundle exec workarea_upgrade report

### View Diffs

Finally, view the actual changes that have occurred to any Workarea gems you 
have installed with:

    bundle exec workarea_upgrade diff

The output of this command will be limited to the files that have been 
overridden or decorated in your application only, as its these files that will
not automatically receive the updates from the core platform. Use this output
to make informed decisions about how your application will need to change to 
stay up to date.

You may also view a list of all files added or removed between each version 
by running either:

    bundle exec workarea_upgrade diff --added # or
    bundle exec workarea_upgrade diff --removed

View `bundle exec workarea_upgrade help diff` for more ways you can format these
results.

### Copy Gemfile.next to Gemfile

Once all of the updates have been applied to your application, move the
`Gemfile.next` files over to replace your `Gemfile` files:

    mv Gemfile.next Gemfile
    mv Gemfile.next.lock Gemfile.lock

### Test

Lastly you should run your test suite to ensure all of the tests pass:

    bin/rails workarea:test

Once the tests pass, deploy your upgrade to your QA environment for real user
testing.

## More Information

Please visit 
<https://developer.workarea.com/articles/upgrading-your-application.html> for a
more comprehensive overview of how to use this plugin.

# Copyright & Licensing

Copyright Weblinc 2017. All rights reserved.

For licensing, contact sales@workarea.com.
