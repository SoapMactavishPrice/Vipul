trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, after insert, after update, after delete) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            OpportunityLineItemTriggerHandler.calculateUnitPrice(Trigger.new);
            //OpportunityLineItemTriggerHandler.handleApproval(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isUpdate) {
            OpportunityLineItemTriggerHandler.storeOldValues(Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            OpportunityLineItemTriggerHandler.updatePreviousValues(Trigger.newMap);
        }

        Set<Id> opportunityIds = new Set<Id>();

        if (Trigger.isInsert || Trigger.isUpdate) {
            for (OpportunityLineItem oli : Trigger.new) {
                opportunityIds.add(oli.OpportunityId);
            }
        }

        if (Trigger.isDelete) {
            for (OpportunityLineItem oli : Trigger.old) {
                opportunityIds.add(oli.OpportunityId);
            }
        }

        // Existing logic
        OpportunityLineItemTriggerHandler.updateSalesPriceFlag(opportunityIds);

        // New logic to update Is_List_Price_0__c
        OpportunityLineItemTriggerHandler.updateListPriceZeroFlag(opportunityIds);
    }
}