public class InvoiceTriggerHandler {
    
    public static void lockOrdersOnInvoiceCreation(List<Invoice__c> invoiceList) {
        Set<Id> orderIds = new Set<Id>();

        // Collect all related Order IDs from Invoices
        for (Invoice__c inv : invoiceList) {
            if (inv.Order__c != null) {
                orderIds.add(inv.Order__c);
            }
        }

        if (!orderIds.isEmpty()) {
            List<Order> ordersToUpdate = new List<Order>();

            // Query Orders to update
            for (Order ord : [SELECT Id, Order_Locked__c FROM Order WHERE Id IN :orderIds]) {
                ord.Order_Locked__c = TRUE; // Lock the order
                ordersToUpdate.add(ord);
            }

            if (!ordersToUpdate.isEmpty()) {
                update ordersToUpdate;
            }
        }
    }

}