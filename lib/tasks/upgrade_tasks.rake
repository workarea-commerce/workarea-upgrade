namespace :weblinc do
  namespace :upgrade do
    desc 'Migrate the database from previous version'
    task migrate: :environment do
      migration = Weblinc::Upgrade::Migration.lookup(Weblinc::VERSION::MAJOR)
      migration.run!

      Rake::Task['db:mongoid:create_indexes'].invoke
      Rake::Task['weblinc:search_index:all'].invoke
    end

    desc 'Calculate a report card to gauge upgrade difficulty'
    task :report_card do
      from = ENV['FROM_VERSION']
      to = ENV['TO_VERSION']

      puts "This rake tasks requires ENV['FROM_VERSION'] to be defined." if from.blank?
      puts "This rake tasks requires ENV['TO_VERSION'] to be defined." if to.blank?

      if from.blank? || to.blank?
        puts 'For example:'
        puts "  rake weblinc:upgrade:report_card FROM_VERSION=0.12.6 TO_VERSION=2.0.3"
        exit
      end

      require 'rails/generators'
      require 'generators/weblinc/diff/diff_generator'

      generator = Weblinc::Generators::DiffGenerator.new([from, to])
      diff = Weblinc::Upgrade::Diff.new(from, to)
      report_card = Weblinc::Upgrade::ReportCard.new(diff)

      puts 'Diff Statistics'
      puts '---------------'
      generator.print_status('---', 'removed', 'red', diff.removed_files)
      generator.print_status('+++', 'added', 'green', diff.added_files)
      generator.print_status('>>>', 'overridden', 'yellow', diff.overridden_files)
      generator.print_status('>>>', 'decorated', 'yellow', diff.decorated_files)

      puts report_card.to_s
    end

    desc 'Read the release notes for the current version'
    task :release_notes do
      # Task goes here
    end
  end
end
