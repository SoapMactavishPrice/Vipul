trigger InvoiceLineItemTrigger_Delete on Invoice_Line_Item__c (after delete) {
    System.debug('====> Delete Trigger: Trigger execution started.');
    
    if (Trigger.isDelete && Trigger.old != null && !Trigger.old.isEmpty()) {
        System.debug('====> Delete event detected. Records to process: ' + Trigger.old.size());
        InvoiceLineItemTriggerHandlerDel.updateQuantityOnTargetDelete(Trigger.old); 
    }
    
    
    
    System.debug('====> Delete Trigger: Trigger execution ended.');
}