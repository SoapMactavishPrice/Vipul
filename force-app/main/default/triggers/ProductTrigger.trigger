trigger ProductTrigger on Product2 (before insert, after insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ProductTriggerHandler.preventDuplicateProducts(Trigger.new);
    }
    
    if (Trigger.isAfter) {
        ProductTriggerHandler.createPricebookEntries(
            Trigger.new,
            Trigger.isUpdate ? Trigger.oldMap : null
        );
    }
}