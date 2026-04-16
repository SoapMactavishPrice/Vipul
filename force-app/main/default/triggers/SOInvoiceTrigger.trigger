trigger SOInvoiceTrigger on Invoice__c (before delete) {
    try {
        System.debug('====> SOInvoiceTrigger started for before delete');

        // Collect IDs of SO_Invoice__c records being deleted
        Set<Id> soInvoiceIds = new Set<Id>();
        for (Invoice__c invoice : Trigger.old) {
            soInvoiceIds.add(invoice.Id);
        }

        System.debug('====> SO_Invoice__c IDs to be deleted: ' + soInvoiceIds);

        if (!soInvoiceIds.isEmpty()) {
            // Fetch related Invoice Line Items
            List<Invoice_Line_Item__c> invoiceLineItemsToDelete = [
                SELECT Id FROM Invoice_Line_Item__c WHERE Invoice__c IN :soInvoiceIds
            ];

            System.debug('====> Found ' + invoiceLineItemsToDelete.size() + ' Invoice Line Items for deletion.');

            if (!invoiceLineItemsToDelete.isEmpty()) {
                // Manually delete child Invoice Line Items
                delete invoiceLineItemsToDelete;
                System.debug('====> Successfully deleted ' + invoiceLineItemsToDelete.size() + ' Invoice Line Items.');
            } else {
                System.debug('====> No Invoice Line Items found for deletion.');
            }
        } else {
            System.debug('====> No SO_Invoice__c records found for deletion.');
        }
    } catch (Exception e) {
        System.debug('====> Exception in SOInvoiceTrigger: ' + e.getMessage());
    }
}