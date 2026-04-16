trigger AccountWiseProductTarget on Account_Wise_Product_Target__c (before insert,after insert, before update, After Update) {

    if(Trigger.isBefore && Trigger.isUpdate) {
        TargetAllInOneTriggerHandler.rollupTargetAmount(Trigger.New, Trigger.oldMap, 'AccountWiseProductTarget');
    }
    
    if(Trigger.isAfter && Trigger.isInsert) {
        TargetAllInOneTriggerHandler.createMonthlyTargetEntries(Trigger.New);
    }
    
   if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
       
        TargetAllInOneTriggerHandler.shareRecordWithUser(Trigger.New, Trigger.oldMap);
    } 
    
    if(Trigger.isAfter && Trigger.isUpdate) {
        TargetAllInOneTriggerHandler.updateMonthlyTargetEntries(Trigger.New, Trigger.oldMap, Trigger.newMap, 'AccountWiseProductTarget');
    }
}