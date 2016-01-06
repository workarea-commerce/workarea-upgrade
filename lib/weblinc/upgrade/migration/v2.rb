module Weblinc
  module Upgrade
    class Migration
      class V2 < Migration
        def perform
          puts "Migrating category data..."
          migrate_categories

          puts "Migrate navigation data..."
          migrate_navigation

          puts "Migrating user data..."
          migrate_users
        end

        def migrate_categories
          categories = Catalog::Category.collection
          smart_categories = Mongoid::Clients.default.collections.detect do |collection|
            collection.namespace == 'weblinc_teststore_development.weblinc_catalog_smart_categories'
          end

          smart_categories.find.each do |category_doc|
            doc = category_doc.except('downcased_name', 'excluded_facets')
            categories.insert_one(doc)
          end
        end

        def migrate_navigation
          Navigation::Link
            .collection
            .update_many(
              { linkable_type: 'Weblinc::Catalog::SmartCategory' },
              { '$set' => { linkable_type: 'Weblinc::Catalog::Category' } }
            )
        end

        def migrate_users
          users = Weblinc::User.collection

          users.find.each do |user_doc|
            passwords = user_doc['passwords'].sort do |a, b|
              a['created_at'] <=> b['created_at']
            end

            current_password = passwords.first
            old_passwords = passwords.from(1)

            old_passwords.each do |password|
              User::RecentPassword.create!(
                user_id: user_doc['_id'],
                password_digest: password['password_digest'],
                created_at: password['created_at']
              )
            end

            users.find(_id: user_doc['_id']).update_one(
              '$unset' => { passwords: '', csr: '' },
              '$set' => {
                password_digest: current_password['password_digest'],
                password_changed_at: current_password['created_at'],
              }
            )
          end
        end
      end
    end
  end
end
