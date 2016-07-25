namespace :weblinc do
  namespace :upgrade do
    desc 'Migrate the database from previous version'
    task migrate: :environment do
      migration = Weblinc::Upgrade::Migration.lookup(Weblinc::VERSION::MAJOR)
      migration.run!

      clean_malformed_email_shares

      Rake::Task['db:mongoid:remove_indexes'].invoke
      Rake::Task['db:mongoid:create_indexes'].invoke
      Rake::Task['weblinc:search_index:all'].invoke
    end

    private

    def clean_malformed_email_shares
      Weblinc::Email::Share.module_eval do
        def sanitize_url; end
      end

      Weblinc::Email::Share.each do |share|
        begin
          URI.parse(share.url)
        rescue URI::InvalidURIError
          share.destroy!
        end
      end
    end
  end
end
