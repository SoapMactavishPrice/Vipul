trigger QuoteTrigger on Quote (before update, after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        QuoteTriggerHandler.createOrder(Trigger.new, Trigger.oldMap);
        QuoteTriggerHandler.syncSAPCodeToProforma(Trigger.new, Trigger.oldMap);
    }
    
    if(Trigger.isBefore && Trigger.isUpdate){
        QuoteTriggerHandler.updateStatusChangeFields(Trigger.new, Trigger.oldMap);
    }
}