Migrating a database from v2 to v3
----------------------------------

The database migration for v3 provides as much automated data migration as possible to do the work required for getting data from v2 of Workarea to v3. There are a number of caveats that will need to be planned for in advance.

* Release changesets will be archived. The changes that would need to be made to changesets to ensure they still apply as intended in non-deterministic. So it is recommended that there be no active releases when doing an upgrade. Releases will not be lost, but the changes associated to them will be moved to a collection call workarea_release_changesets_archived. They can be accessed through mongo if needed, but not available through the Workarea::Release::Changeset model.

* All audit log entries will be archived. Much like changesets, log entries cannot be reliably migrated to display and link to the changed resources. Workarea v3 also adds in more information via document_path that allows a more robust behavior in regards to the activity feeds in the admin. These cannot be generated from the data stored by v2 audit log entries. Logs will still be availabe in mongodb in the mongoid_audit_log_entries_archived collection if needed.

* Content block types have changed in base. Any block types being used in your v2 system, or added while building on v2, will need to exist in your content block type configuration in order to be brought into the new system. Otherwise, they will be deleted. The content block type collection is archived for your reference at workarea_content_block_types_archived. Blocks which utilize assets used urls in v2. In v3, the id of the corresponding asset is used instead. The migration script attempts to find the asset based on url and set it for the hero content block, but this is not foolproof and it is recommended you review content blocks and ensure their assets are preset and adjust accordingly.

* Paranoid Deleted documents are moved to a \_deleted collection. If an existing collection had previously deleted documents in it, via deleted_at, they will be removed from the collection into a collection of the same name, appended with the \_deleted suffix. If clients need access to these documents you will have to manually manage pulling them out of the deleted collection back into the standard collection.

* Dashboard models were removed in favor of Analytics. This data cannot be recreated in the form that v3 expects. The dashboard collections are left unchanged other than the collection name switching from weblinc_ to workarea_. It can be accessed through mongodb and is recommended you work with your client to determine what, if anything, needs to be done.

* Help articles will migrate over. However, most of these will be outdated and not relevant to v3, so it is recommended you take any custom help articles out, update the base articles and update the project's custom articles.

* Product purchase dates and Pricing Sku sale dates are removed. Workarea v2 products have purchase_starts_at and purchase_ends_at, and Inventory Skus have sale_starts_at and sale_ends_at. These were removed in v3 in favor of a boolean field, purchasable and on_sale respectively, allowing the use of the existing release system to control this behavior. The migration will set the field based on the current date in relation to the old dates. This does result in data loss that will need to be accounted for when migrating from v2.

It is recommended you review the migration script and modify as needed based on the needs and customization of your project specifically. This is not a one-size-fits-all migration and will not work for any and all projects. We provide this as a starting point of a v2 base to v3 base migration.

0. Update your application for v3 compatibility.
1. Review the migration script with relation to your project.
2. Make the necessary modifications/additions.
3. Ensure your database is backed up.
4. Run the migration.
5. Verify the data is feeding to your application as expected.
6. Take the above caveats into consideration and make an necessary changes to your data.