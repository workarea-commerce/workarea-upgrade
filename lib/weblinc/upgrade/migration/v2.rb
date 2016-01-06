module Weblinc
  module Upgrade
    class Migration
      class V2 < Migration
        def perform
          puts "Migrating user data..."
          migrate_users
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
