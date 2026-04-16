trigger QuoteLineItemTrigger on QuoteLineItem (before insert,before update,after update, after delete) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            System.debug('Description:');
            QuoteLineItemTriggerHandler.updateDescription(Trigger.new);
            QuoteLineItemTriggerHandler.calculateUnitPrice(Trigger.new);         
        }
        if (Trigger.isUpdate) {
            QuoteLineItemTriggerHandler.storeOldValues(Trigger.oldMap);
        }
    }
    
    
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            QuoteLineItemTriggerHandler.updatePreviousValues(Trigger.newMap);
        }

        // ✅ Collect Quote IDs from new or old records
        Set<Id> quoteIds = new Set<Id>();

        if (Trigger.isInsert || Trigger.isUpdate) {
            for (QuoteLineItem qli : Trigger.new) {
                quoteIds.add(qli.QuoteId);
            }
        }

        if (Trigger.isDelete) {
            for (QuoteLineItem qli : Trigger.old) {
                quoteIds.add(qli.QuoteId);
            }
        }

        // ✅ Existing logic
        QuoteLineItemTriggerHandler.updateSalesPriceFlag(quoteIds);

        // ✅ New logic to update Is_List_Price_0__c
        QuoteLineItemTriggerHandler.updateListPriceZeroFlag(quoteIds);
    }
}