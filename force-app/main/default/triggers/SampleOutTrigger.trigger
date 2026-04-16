trigger SampleOutTrigger on Sample_Out__c (before insert, before update, after insert, after update, after delete, after undelete) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            SampleOutTriggerHandler.populateFieldsFromRequest(Trigger.new);
        }
       /* if (Trigger.isUpdate) {
            SampleOutTriggerHandler.captureStatusChangeDates(Trigger.new, Trigger.oldMap);
        }  */
        
        if (Trigger.isBefore) {
            if (Trigger.isInsert || Trigger.isUpdate) {
                SampleOutTriggerHandler.captureStatusChangeDates(
                    Trigger.new,
                    Trigger.oldMap
                );
            }
        }

    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            SampleOutTriggerHandler.createSampleOutRecords(Trigger.new);
        }
        if (Trigger.isUpdate) {
            SampleOutTriggerHandler.syncStatusToSampleOut(Trigger.new, Trigger.oldMap);
            SampleOutTriggerHandler.handleReSamplingEmail(Trigger.new, Trigger.oldMap);
        }
        
        // Add logic to update parent Sample_In_Request__c status
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete || Trigger.isUndelete) {
            SampleOutTriggerHandler.updateSampleOutRequestStatus(Trigger.newMap, Trigger.oldMap);
        }
        
    }
    
    
}