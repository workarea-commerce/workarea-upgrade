module Workarea
  module Upgrade
    class Migration
      class V2 < Migration
        def perform
          Workarea::Publisher.disable
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

          puts "Migrating discount data..."
          migrate_discounts

          puts "Migrating user data..."
          migrate_users

          puts 'Migrating fulfillment orders...'
          migrate_fulfillment
          Workarea::Publisher.enable

          puts 'Migration email shares...'
          clean_malformed_email_shares
        end

        def migrate_categories
          categories = Catalog::Category.collection
          excluded_facets = {}

          categories.find.each do |category_doc|
            if category_doc['excluded_facets'].present?
              excluded_facets[category_doc['_id']] = category_doc['excluded_facets']
            end
          end

          smart_categories = Mongoid::Clients.default.collections.detect do |collection|
            collection.namespace.end_with?('weblinc_catalog_smart_categories')
          end

          smart_categories.find.each do |category_doc|
            doc = category_doc.except('downcased_name', 'excluded_facets')
            doc['slug'] = SecureRandom.hex(10) unless doc['deleted_at'].nil?
            categories.insert_one(doc)
          end

          if excluded_facets.present?
            warn "Unsetting excluded_facets on all categories. Please see category_excluded_facets.json for a dump of the data"
            File.open('category_excluded_facets.json', 'w') do |file|
              file.write(excluded_facets.to_json)
            end
          end

          categories.update_many(
            {},
            { '$unset' => { downcased_name: '', excluded_facets: '' } }
          )
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

              next if categorization_doc['category_id'].nil?

              category = if existing
                           existing
                         else
                           begin
                             categories_to_save << Catalog::Category.find(categorization_doc['category_id'])
                             categories_to_save.last
                           rescue Mongoid::Errors::DocumentNotFound
                             next
                           end
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

          Content
            .collection
            .update_many({}, { '$unset' => { downcased_name: '' } })
        end

        def migrate_orders
          orders = Order.collection
          segment_data = {}

          orders.find.each do |order_doc|
            if order_doc['segment_ids'].present?
              segment_data[order_doc['number']] = order_doc['segment_ids']
            end
            orders.update_one(
              { _id: order_doc['_id'] },
              '$unset' => { cancelled_at: '' },
              '$set' => { canceled_at: order_doc['cancelled_at'] }
            )
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
                "items.#{i}.digital" => '',
                "items.#{i}.product_attributes.packaged_product_ids" => '',
                "items.#{i}.product_attributes.categorizations" => ''
              }
            )
          end
        end

        def migrate_discounts
          new_discounts = Workarea::Pricing::Discount.collection
          compatibility_data = {}

          discounts = Mongoid::Clients.default.collections.detect do |collection|
            collection.namespace.end_with?('weblinc_pricing_discounts_discounts')
          end

          discounts.find.each do |discount_doc|
            discount_doc['_type'] = discount_doc['_type'].gsub('Discounts', 'Discount')

            if discount_doc['incompatible_discount_ids'].present?
              compatibility_data[discount_doc['_id']] = discount_doc['incompatible_discount_ids']
            end

            new_discounts.insert_one(discount_doc.except('incompatible_discount_ids'))
          end

          if compatibility_data.present?
            warn "Unsetting incompatible_discount_ids on all discounts. All discounts are incompatible by default now. Please see incompatible_discount_ids.json for a dump of the data"
            File.open('incompatible_discount_ids.json', 'w') do |file|
              file.write(compatibility_data.to_json)
            end
          end

          promo_codes = Mongoid::Clients.default.collections.detect do |collection|
            collection.namespace.end_with?('weblinc_pricing_discounts_generated_promo_codes')
          end

          promo_codes.find.each do |promo_code_doc|
            Workarea::Pricing::Discount::GeneratedPromoCode.collection.insert_one(promo_code_doc)
          end

          redemptions = Mongoid::Clients.default.collections.detect do |collection|
            collection.namespace.end_with?('weblinc_pricing_discounts_redemptions')
          end

          redemptions.find.each do |redemption_doc|
            Workarea::Pricing::Discount::Redemption.collection.insert_one(redemption_doc)
          end
        end

        def migrate_users
          users = Workarea::User.collection
          users.indexes.drop_one('token_1')

          warn "User permissions have changed. Former permissions data still available in the `weblinc_user_authorizations` collection. You will need to manually migrate those. Please see the v2.0 release notes at http://guides.weblinc.com/release-notes.html"

          users.find.each do |user_doc|
            next if user_doc['passwords'].nil?

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

        def migrate_fulfillment
          new_fulfillments = Fulfillment.collection

          fulfillments = Mongoid::Clients.default.collections.detect do |c|
            c.namespace.end_with?('weblinc_fulfillment_orders')
          end

          fulfillments.find.each do |fulfillment_doc|
            fulfillment_doc['_id'] = fulfillment_doc.delete('number')

            shipments_doc = fulfillment_doc.delete('shipments')
            cancellations_doc = fulfillment_doc.delete('cancellations')
            returns_doc = fulfillment_doc.delete('returns')

            fulfillment_doc['items'].each do |item|
              item.delete('quantity_cancelled')
              item.delete('quantity_returned')
              item.delete('quantity_shipped')

              item['events'] ||= []

              unless cancellations_doc.nil?
                cancellations_for_item = for_order_item_id(cancellations_doc, item['order_item_id'])
                cancellations_for_item.each do |cancellation|
                  item['events'].push(
                    id: BSON::ObjectId.new,
                    status: 'canceled',
                    quantity: cancellation['quantity'],
                    created_at: cancellation['created_at'],
                    updated_at: cancellation['updated_at']
                  )
                end
              end

              unless shipments_doc.nil?
                shipments_doc.each do |shipment|
                  shipment_items_for_item = for_order_item_id(shipment['items'], item['order_item_id'])
                  next if shipment_items_for_item.blank?
                  shipment_items_for_item.each do |sifi|
                    item['events'].push(
                      id: BSON::ObjectId.new,
                      status: 'shipped',
                      quantity: sifi['quantity'],
                      data: {
                        tracking_number: shipment['tracking_number']
                      }
                    )
                  end
                end
              end

              unless returns_doc.nil?
                returns_for_item = for_order_item_id(returns_doc, item['order_item_id'])
                returns_for_item.each do |rtrn|
                  item['events'].push(
                    id: BSON::ObjectId.new,
                    status: 'returned',
                    quantity: rtrn['quantity'],
                    created_at: rtrn['created_at'],
                    updated_at: rtrn['updated_at'],
                    data: {
                      reason_code: rtrn['reason_code']
                    }
                  )
                end
              end
            end

            new_fulfillments.insert_one(fulfillment_doc)
          end
        end


        def clean_malformed_email_shares
          Workarea::Email::Share.module_eval do
            def sanitize_url; end
          end

          Workarea::Email::Share.each do |share|
            begin
              URI.parse(share.url)
            rescue URI::InvalidURIError
              share.destroy!
            end
          end
        end

        private

        def for_order_item_id(docs, order_item_id)
          docs.select do |doc|
            doc['order_item_id'] == order_item_id
          end
        end
      end
    end
  end
end
