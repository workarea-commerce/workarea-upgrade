module Workarea
  module Upgrade
    class Migration
      class V3 < Migration
        def initialize(*args)
          @client = Mongoid::Clients.default
          super(*args)
        end

        def perform
          Sidekiq::Callbacks.disable

          puts 'Renaming collections...'
          rename_collections

          puts 'Archiving activity logs...'
          archive_activity_logs

          puts 'Migrating categories...'
          update_categories

          puts 'Migrating products...'
          update_products
          clear_product_placeholder_image

          puts 'Migrating content...'
          update_content
          remove_content_block_types
          update_content_assets
          update_content_presets
          update_pages

          puts 'Migrating comments...'
          update_comments

          puts 'Migrating inventory...'
          update_inventory_transactions

          puts 'Migrating inquiries...'
          update_inquiries

          puts 'Migrating navigation...'
          rename_navigation_links
          update_navigation_taxons
          update_navigation_menus

          puts 'Migrating orders...'
          update_orders

          puts 'Migrating payments...'
          update_payments

          puts 'Migrating pricing...'
          update_discounts
          update_pricing_skus

          puts 'Migrating recommendations...'
          update_recommendation_settings
          update_user_activity

          puts 'Migrating releases...'
          update_releases
          update_release_changesets

          puts 'Migrating search...'
          # remove_search_click_throughs
          update_search_customizations
          # remove_search_logged_queries
          update_search_settings

          puts 'Migrating shipping...'
          rename_shipping_shipment
          update_shipping
          rename_shipping_method
          update_shipping_services

          puts 'Migrating users...'
          update_users

          puts 'Archiving deleted documents...'
          archive_deleted_records

          Sidekiq::Callbacks.enable
        end

        def rename_collections
          @client.database.collections.each do |collection|
            new_name = collection.namespace.gsub('weblinc', 'workarea')
            next unless collection.namespace != new_name

            rename_collection(collection.namespace, new_name)
          end
        end

        def archive_activity_logs
          collection = Mongoid::AuditLog::Entry.collection
          new_name = "#{collection.namespace}_archived"
          return if @client.database.collection_names.include?(new_name)

          rename_collection(collection.namespace, new_name)
          collection.drop
        end

        def update_categories
          collection = Workarea::Catalog::Category.collection

          persist_document_changes(collection) do |category_doc|
            category_doc['term_facets'] = category_doc.delete('filters')
            category_doc['range_facets'] = category_doc.delete('range_filters')
            update_commentable_fields(category_doc)

            Array.wrap(category_doc['rules']).each do |rule_doc|
              rule_doc['name'] = rule_doc.delete('field')
            end

            category_doc['product_rules'] = category_doc.delete('rules') if category_doc['rules'].present?
          end
        end

        def update_products
          collection = Workarea::Catalog::Product.collection

          persist_document_changes(collection) do |product_doc|
            product_doc['purchasable'] = (
              (
                product_doc['purchase_starts_at'].blank? ||
                product_doc['purchase_starts_at'] < Time.now
              ) &&
              (
                product_doc['purchase_ends_at'].blank? ||
                product_doc['purchase_ends_at'] > Time.now
              )
            )

            product_doc.delete('purchase_starts_at')
            product_doc.delete('purchase_ends_at')
            product_doc.delete('meta_keywords')

            Array.wrap(product_doc['variants']).each do |variant_doc|
              variant_doc['active'] = true
              variant_doc.delete('purchase_starts_at')
              variant_doc.delete('purchase_ends_at')
            end

            update_commentable_fields(product_doc)
          end
        end

        def clear_product_placeholder_image
          Workarea::Catalog::ProductPlaceholderImage.collection.drop
        end

        def update_content
          collection = Workarea::Content.collection

          persist_document_changes(collection) do |content_doc|
            update_commentable_fields(content_doc)

            content_doc.delete('meta_keywords')

            content_doc['contentable_type'] =
              content_doc['contentable_type'].try(:sub, 'Weblinc', 'Workarea')

            areas   = Workarea.config.content_areas[content_doc['name'].slugify] if content_doc['contentable_type'].blank?
            areas ||= Workarea.config.content_areas['category'] if content_doc['contentable_type'] =~ /Category/
            areas ||= Workarea.config.content_areas['generic']

            content_doc['blocks']= Array.wrap(content_doc['blocks']).map do |block_doc|
              block_doc['type_id'] = 'text' if block_doc['type_id'] == 'rich_text'
              type = Workarea::Content::BlockType.find(block_doc['type_id'].to_sym)
              next unless type.present?

              block_doc['area'] = areas.first unless block_doc['area'].in?(areas)
              update_content_block_data(block_doc['data'], block_doc['type_id'])
              block_doc
            end.compact
          end
        end

        def remove_content_block_types
          collection =
            @client.database.collections.detect { |c| c.namespace =~ /block_types/ }
          return unless collection.present?

          new_name = "#{collection.namespace}_archived"
          return if @client.database.collection_names.include?(new_name)

          rename_collection(collection.namespace, new_name)
        end

        def update_content_assets
          collection = Workarea::Content::Asset.collection

          persist_document_changes(collection) do |asset_doc|
            update_commentable_fields(asset_doc)
          end
        end

        def update_content_presets
          collection = Workarea::Content::Preset.collection

          persist_document_changes(collection) do |preset_doc|
            preset_doc['type_id'] = 'text' if preset_doc['type_id'] == 'rich_text'
            update_content_block_data(preset_doc['data'], preset_doc['type_id'])
          end
        end

        def update_pages
          collection = Workarea::Content::Page.collection

          persist_document_changes(collection) do |page_doc|
            page_doc['show_navigation'] = page_doc.delete('navigation').present?
            update_commentable_fields(page_doc)
          end
        end

        def update_comments
          collection = Workarea::Comment.collection

          persist_document_changes(collection) do |comment_doc|
            comment_doc['commentable_type'] =
              comment_doc['commentable_type'].sub('Weblinc', 'Workarea')
          end
        end

        def update_inventory_transactions
          collection = Workarea::Inventory::Transaction.collection

          persist_document_changes(collection) do |transaction_doc|
            transaction_doc['order_id'] = transaction_doc.delete('order_id')
          end
        end

        def update_inquiries
          collection = Workarea::Inquiry.collection

          persist_document_changes(collection) do |inquiry_doc|
            inquiry_doc['order_id'] = inquiry_doc.delete('order_number')
          end
        end

        def rename_navigation_links
          collection =
            @client.database.collections.detect { |c| c.namespace =~ /navigation_links/ }
          return unless collection.present?

          rename_collection(
            collection.namespace,
            collection.namespace.sub('navigation_links', 'navigation_taxons')
          )
        end

        def update_navigation_taxons
          collection = Workarea::Navigation::Taxon.collection

          persist_document_changes(collection) do |taxon_doc|
            taxon_doc['navigable_type'] = taxon_doc.delete('linkable_type').try(:sub, 'Weblinc', 'Workarea')
            taxon_doc['navigable_id'] = taxon_doc.delete('linkable_id')
            taxon_doc['navigable_slug'] = taxon_doc.delete('linkable_slug')
            taxon_doc.delete('sales_score')
            taxon_doc.delete('previous_sales_score')
            taxon_doc.delete('search')
          end
        end

        def update_navigation_menus
          collection = Workarea::Navigation::Menu.collection
          active_root_ids = collection.find
                                      .map { |d| d['root_id'] }
                                      .reject(&:blank?)
                                      .map(&:to_s)

          return unless active_root_ids.present?
          collection.drop

          Workarea::Navigation::Taxon.where(parent_id: nil).each do |taxon|
            if active_root_ids.include?(taxon.id.to_s)
              taxon.children.each do |child|
                child.update_attributes!(parent_id: nil)
                Workarea::Navigation::Menu.create!(taxon: child)
              end
            else
              taxon.destroy
            end
          end
        end

        def update_orders
          Workarea::Order.remove_indexes
          collection = Workarea::Order.collection

          persist_document_changes(collection) do |order_doc|
            next if order_doc['number'].nil?

            order_doc['_id'] = order_doc.delete('number')
            update_commentable_fields(order_doc)
            update_order_items(order_doc['items'])
          end
        end

        def update_order_items(items)
          Array.wrap(items).each do |item_doc|
            item_doc.delete('contributes_to_shipping')

            Array.wrap(item_doc['price_adjustments']).each do |adjustment_doc|
              adjustment_doc['calculator'] =
                adjustment_doc['calculator'].try(:sub, 'Weblinc', 'Workarea')
            end

            if item_doc['product_attributes'].present?
              attr_doc = item_doc['product_attributes']

              attr_doc.delete('meta_keywords')

              # Localization is not present in V2 order item product attributes
              attr_doc['details'] = { 'en' => attr_doc['details'] }
              attr_doc['filters'] = { 'en' => attr_doc['filters'] }
              attr_doc['description'] = { 'en' => attr_doc['description'] }
              attr_doc['name'] = { 'en' => attr_doc['name'] }
              attr_doc['browser_title'] = { 'en' => attr_doc['browser_title'] }

              Array.wrap(attr_doc['variants']).each do |variant_doc|
                variant_doc['details'] = { 'en' => variant_doc['details'] }
                variant_doc['name'] = { 'en' => variant_doc['name'] }
              end
            end
          end
        end

        def update_discounts
          collection = Workarea::Pricing::Discount.collection

          persist_document_changes(collection) do |dicount_doc|
            dicount_doc['_type'] = dicount_doc['_type'].try(:gsub, 'Weblinc', 'Workarea')
            update_commentable_fields(dicount_doc)

            if dicount_doc['_type'] = 'Workarea::Pricing::Discount::Shipping'
              dicount_doc['shipping_service'] = dicount_doc.delete('shipping_method')
            end
          end
        end

        def update_pricing_skus
          collection = Workarea::Pricing::Sku.collection

          persist_document_changes(collection) do |sku_doc|
            sku_doc['on_sale'] = (
              (
                sku_doc['sale_starts_at'].blank? ||
                sku_doc['sale_starts_at'] < Time.now
              ) &&
              (
                sku_doc['sale_ends_at'].blank? ||
                sku_doc['sale_ends_at'] > Time.now
              )
            )

            sku_doc.delete('sale_starts_at')
            sku_doc.delete('sale_ends_at')
            sku_doc['active'] = true

            Array.wrap(sku_doc['prices']).each do |price_doc|
              price_doc['active'] = true
            end
          end
        end

        def update_recommendation_settings
          collection = Workarea::Recommendation::Settings.collection

          persist_document_changes(collection) do |settings_doc|
            settings_doc['_id'] = settings_doc.delete('product_id')
          end
        end

        def update_user_activity
          collection = Workarea::Recommendation::UserActivity.collection

          persist_document_changes(collection) do |activity_doc|
            activity_doc['_id'] = activity_doc.delete('user_id')
          end
        end

        def update_releases
          collection = Workarea::Release.collection

          persist_document_changes(collection) do |release_doc|
            update_commentable_fields(release_doc)
          end
        end

        def update_release_changesets
          collection = Workarea::Release::Changeset.collection

          persist_document_changes(collection) do |changeset_doc|
            changeset_doc['releasable_type'] =
              changeset_doc['releasable_type'].sub('Weblinc', 'Workarea')
          end

          rename_collection(
            collection.namespace,
            "#{collection.namespace}_archived"
          )
        end

        def update_search_customizations
          collection = Workarea::Search::Customization.collection

          persist_document_changes(collection) do |customization_doc|
            customization_doc['active'] = true
            update_commentable_fields(customization_doc)
          end
        end

        def update_search_settings
          collection = Search::Settings.collection

          persist_document_changes(collection) do |settings_doc|
            settings_doc['term_facets'] = settings_doc.delete('filters')
            settings_doc['range_facets'] = settings_doc.delete('range_filters')
          end
        end

        def rename_shipping_shipment
          collection =
            @client.database.collections.detect { |c| c.namespace =~ /shipping_shipments/ }
          return unless collection.present?

          rename_collection(
            collection.namespace,
            collection.namespace.sub('shipping_shipments', 'shippings')
          )
        end

        def update_shipping
          collection = Workarea::Shipping.collection

          persist_document_changes(collection) do |shipping_doc|
            shipping_doc['order_id'] = shipping_doc.delete('number')
            shipping_doc['shipping_service'] = shipping_doc.delete('shipping_method')

            Array.wrap(shipping_doc['price_adjustments']).each do |adjustment_doc|
              adjustment_doc['calculator'] =
                adjustment_doc['calculator'].try(:sub, 'Weblinc', 'Workarea')
            end

            address_doc = shipping_doc['address']
            address_doc['_type'] = 'Workarea::Shipping::Address' if address_doc.present?

            @client["#{collection.name}_items_archived"].insert_one(
              order_id: shipping_doc['order_id'],
              items: shipping_doc.delete('items')
            )
          end
        end

        def rename_shipping_method
          collection =
            @client.database.collections.detect { |c| c.namespace =~ /shipping_methods/ }
          return unless collection.present?

          rename_collection(
            collection.namespace,
            collection.namespace.sub('shipping_methods', 'shipping_services')
          )
        end

        def update_shipping_services
          collection = Workarea::Shipping::Service.collection

          persist_document_changes(collection) do |service_doc|
            service_doc['regions'] = Array.wrap(
              service_doc.delete('region')
            ).compact
          end
        end

        def update_users
          collection = Workarea::User.collection

          persist_document_changes(collection) do |user_doc|
            analytics = Workarea::Analytics::User.find_or_initialize_by(id: user_doc['email'])
            analytics.total_orders = user_doc.delete('total_orders') if user_doc['total_orders'].present?
            analytics.last_purchase_at = user_doc.delete('last_purchase_at') if user_doc['last_purchase_at'].present?
            analytics.total_spent = user_doc.delete('total_spent') if user_doc['total_spent'].present?
            analytics.signed_up_at = user_doc['created_at']
            analytics.save!

            update_commentable_fields(user_doc)

            Array.wrap(user_doc['addresses']).each do |address_doc|
              address_doc['_type'] = 'Workarea::User::SavedAddress'
            end
          end
        end

        def update_payments
          collection = Workarea::Payment.collection

          persist_document_changes(collection) do |payment_doc|
            payment_doc['order_id'] = payment_doc.delete('number')

            address_doc = payment_doc['address']
            address_doc['_type'] = 'Workarea::Address' if address_doc.present?

            Workarea.config.tender_types.each do |type|
              tender_doc = payment_doc[type]
              tender_doc['_type'] = tender_doc['_type'].try(:sub, 'Weblinc', 'Workarea') if tender_doc.present?
            end
          end
        end

        def archive_deleted_records
          filter = { deleted_at: { '$gt' => 0 }}

          [
            Workarea::Catalog::Category,
            Workarea::Catalog::Product,
            Workarea::Content,
            Workarea::Content::Page,
            Workarea::Fulfillment,
            Workarea::Help::Article,
            Workarea::Order,
            Workarea::Payment::SavedCreditCard,
            Workarea::Pricing::Discount,
            Workarea::Release,
            Workarea::Shipping,
            Workarea::User
          ].each do |model|
            collection = model.collection

            @client["#{collection.name}_deleted"].insert_many(
              collection.find(filter).to_a
            )

            collection.delete_many(filter)
            collection.update_many({}, { '$unset' => { deleted_at: '' } })
          end
        end

        private

        def persist_document_changes(collection)
          collection.find.each do |document|
            original_document = document.deep_dup
            yield(document)
            next if original_document == document

            if original_document['_id'] == document['_id']
              find_and_replace(collection, original_document['_id'], document)
            else
              delete_and_insert(collection, original_document['_id'], document)
            end
          end
        end

        def find_and_replace(collection, id, document)
          collection.find_one_and_replace({ '_id' => id }, document)
        end

        def delete_and_insert(collection, id, document)
          collection.delete_one({ '_id' => id })
          collection.insert_one(document)
        end

        def rename_collection(old_name, new_name)
          @client.use("admin").database.command({
            "renameCollection" => old_name,
            "to" => new_name,
            "dropTarget" => true # w/o this, it will faill if collection exists
          })
        end

        def update_commentable_fields(doc)
          doc['subscribed_user_ids'] ||= doc.delete('notify_user_ids')
        end

        def update_content_block_data(data, type)
          data.each do |_, doc| # each locale
            doc['position'] = doc.delete('text_link_position') if doc['text_link_position'].present?
            doc['category'] = doc.delete('category_id') if doc['category_id'].present?
            doc['products'] = doc.delete('product_ids') if doc['product_ids'].present?
            doc['text'] = doc.delete('html') if type == 'text'
            doc['asset'] = find_asset_from_url(doc['image']) if type == 'hero'
          end
        end

        def find_asset_from_url(url)
          Workarea::Content::Asset.all.detect do |asset|
            url[asset.url].present?
          end.try(:id) || Workarea::Content::BlockType.find(:hero).defaults[:asset]
        end
      end
    end
  end
end
