namespace :weblinc do
  namespace :upgrade do
    desc 'Migrate the database from previous version'
    task migrate: :environment do
      migration = Weblinc::Upgrade::Migration.lookup(Weblinc::VERSION::MAJOR)
      migration.run!

      Rake::Task['db:mongoid:create_indexes'].invoke
      Rake::Task['weblinc:search_index:all'].invoke
    end

    desc 'Read the release notes for the current version'
    task :release_notes do
      # Task goes here
    end
  end
end
