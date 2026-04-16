trigger InvoiceTrigger on Invoice__c (after insert) {
    
    InvoiceTriggerHandler.lockOrdersOnInvoiceCreation(Trigger.New);

}