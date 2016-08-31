WebLinc Upgrade 1.0.2 (2016-08-30)
--------------------------------------------------------------------------------

*   Require active_support delegation method for compatibility with weblinc v2.2.x

    UPGRADE-9
    Matt Duffy

*   Fixing various issues found in data migration scripts

    Running data migration on real life data revealed several issues with the
    migration scripts that I addressed as they came up.

    * Create a method to migrate fulfillment data
    * Removal of 'packaged_product_ids' and 'categorizations' from
    'product_attributes' in 'order.items'
    * Guard against users having no passwords because of sign in through facebook
    or other third party
    * 'cancelled_at' to 'canceled_at' on orders
    * Guard against possibility of duplicate slugs from deleted Smart Categories
    * Guard against non-existent categories in product.categorizations
    * Added 'db:mongoid:remove_indexes' invocation
    * Cleaning of possible malformed URLs in Email::Share

    UPGRADE-8
    Jesse McPherson

*   UPGRADE-7: update documentation to ensure target versions are installed
    prior to to running the diff or report
    fgalarza


WebLinc Upgrade 1.0.1 (2016-04-05)
--------------------------------------------------------------------------------


Weblinc Upgrade 1.0.0 (February 18, 2016)
--------------------------------------------------------------------------------

*   Add CLI tools for diffing weblinc versions

*   Add a report to help a developer understand and begin an upgrade

*   Add migration for migrating from v0.12 to v2.0
