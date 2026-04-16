trigger SampleOutProductsTrigger on Sample_Out_Products__c (before insert, after insert, after update) {
    
    
    if (Trigger.isBefore && Trigger.isInsert) {
        SampleOutProductTriggerHandler.populateFieldsFromPreviousSampleOut(Trigger.new);
        SampleOutProductTriggerHandler.populateFieldsFromPreviousSampleOutForOut(Trigger.new);
    }
    
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        SampleOutProductTriggerHandler.updateSampleInStatus(Trigger.new, Trigger.oldMap);
        SampleOutProductTriggerHandler.updateSampleOutStatus(Trigger.new, Trigger.oldMap);
        SampleOutProductTriggerHandler.syncFieldsToSampleIn(Trigger.new, Trigger.oldMap);
    }
    
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        //SampleOutProductTriggerHandler.syncFieldsToSampleIn(Trigger.new, Trigger.oldMap);
        SampleOutProductTriggerHandler.syncToSampleOut(Trigger.new);
    }

    
}