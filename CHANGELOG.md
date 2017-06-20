Workarea Upgrade 2.0.1 (2017-06-20)
--------------------------------------------------------------------------------

*   Fix issues with v3 migration script

    - Handle Products without variants
    - Handle Pricing::Sku without prices
    - Handle indexing orders after changing IDs
    - Remove purchase dates from variants
    - Remove meta_keywords from products and content
    - Check order number presence to prevent looping through new documents

    UPGRADE-20
    Matt Duffy

*   Modify diffing logic to allow diff between v3 versions

    UPGRADE-19
    Matt Duffy

*   Remove incorrect reference to Weblinc constant

    UPGRADE-18
    Matt Duffy


Workarea Upgrade 2.0.0 (2017-05-05)
--------------------------------------------------------------------------------

*   Allow workarea gems to be diffed with weblinc gems

    UPGRADE-16
    Matt Duffy

*   Create v3 database migration script

    UPGRADE-15
    Matt Duffy


WebLinc Upgrade 1.1.0 (2016-10-12)
--------------------------------------------------------------------------------

*   Add support for .decorator files

    UPGRADE-13
    Ben Crouse


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
