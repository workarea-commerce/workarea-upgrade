namespace :workarea do
  namespace :upgrade do
    desc 'Migrate the database from previous version'
    task migrate: :environment do
      migration = Workarea::Upgrade::Migration.lookup(Workarea::VERSION::MAJOR)
      migration.run!

      Rake::Task['db:mongoid:remove_indexes'].invoke
      Rake::Task['db:mongoid:create_indexes'].invoke

      if WORKAREA_ALIASED
        Rake::Task['weblinc:search_index:all'].invoke
      else
        Rake::Task['workarea:search_index:all'].invoke
      end
    end
  end
end
