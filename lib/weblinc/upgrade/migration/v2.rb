module Weblinc
  module Upgrade
    class Migration
      class V2 < Migration
        def perform
          puts "Migrating category data..."
          migrate_categories

          puts "Migrating product data..."
          migrate_products

          puts "Migrating navigation data..."
          migrate_navigation

          puts "Migrating content data..."
          migrate_content

          puts "Migrating order data..."
          migrate_orders

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

        def migrate_products
          I18n.for_each_locale do |locale|
            Search::Repositories::ProductBrowse.new.reset!
          end

          products = Catalog::Product.collection
          categories_to_save = []
          packaged_product_data = {}

          products.find.each do |product_doc|
            if product_doc['packaged_product_ids'].present?
              packaged_product_data[product_doc['_id']] = product_doc['packaged_product_ids']
            end

            next unless product_doc['categorizations'].present?

            product_doc['categorizations'].each do |categorization_doc|
              existing = categories_to_save.detect { |c| c.id.to_s == categorization_doc['category_id'].to_s }

              category = if existing
                           existing
                         else
                           categories_to_save << Catalog::Category.find(categorization_doc['category_id'])
                           categories_to_save.last
                         end

              if categorization_doc['position'].present?
                category.product_ids.insert(
                  categorization_doc['position'],
                  product_doc['_id']
                )
              else
                category.product_ids.push(product_doc['_id'])
              end
            end
          end

          if packaged_product_data.present?
            warn "Unsetting packaged_product_ids on all products. Please see packaged_products.json for a dump of the data"
            File.open('packaged_products.json', 'w') do |file|
              file.write(packaged_product_data.to_json)
            end
          end

          products.update_many(
            {},
            '$unset' => { categorizations: '', packaged_product_ids: '' }
          )

          categories_to_save.each(&:save!)
        end

        def migrate_navigation
          Navigation::Link
            .collection
            .update_many(
              { linkable_type: 'Weblinc::Catalog::SmartCategory' },
              { '$set' => { linkable_type: 'Weblinc::Catalog::Category' } }
            )
        end

        def migrate_content
          Content
            .collection
            .update_many(
              { contentable_type: 'Weblinc::Catalog::SmartCategory' },
              { '$set' => { contentable_type: 'Weblinc::Catalog::Category' } }
            )
        end

        def migrate_orders
          orders = Order.collection
          segment_data = {}

          orders.find.each do |order_doc|
            if order_doc['segment_ids'].present?
              segment_data[order_doc['number']] = order_doc['segment_ids']
            end
          end

          if segment_data.present?
            warn "Unsetting segment_ids on all orders. Please see order_segments.json for a dump of the data"
            File.open('order_segments.json', 'w') do |file|
              file.write(segment_data.to_json)
            end
          end

          orders.update_many({}, '$unset' => { segment_ids: '' })

          # 100 hardcoded because there's no way to remove these elements from
          # every item (limitation of Mongodb).
          #
          # 100 was used because it's hard to imagine a cart with more than 100
          # items.
          #
          100.times do |i|
            orders.update_many(
              { "items.#{i}" => { '$exists' => true } },
              '$unset' => {
                "items.#{i}.product_details" => '',
                "items.#{i}.sku_details" => '',
                "items.#{i}.digital" => ''
              }
            )
          end
        end

        def migrate_users
          users = Weblinc::User.collection
          users.indexes.drop_one('token_1')

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

            users.update_one(
              { _id: user_doc['_id'] },
              '$unset' => { passwords: '', csr: '', token: '' },
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
