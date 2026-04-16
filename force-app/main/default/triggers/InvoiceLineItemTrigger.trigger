trigger InvoiceLineItemTrigger on Invoice_Line_Item__c (after insert, after update) {

    InvoiceLineItemTriggerHandler.updateQuantityOnTarget(Trigger.new);
}