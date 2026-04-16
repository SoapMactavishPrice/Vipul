trigger SampleInTrigger on Sample_In__c (before insert, after insert, after update, before update, after delete, after undelete) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            SampleInTriggerHandler.populateFieldsFromRequest(Trigger.new);
        }

        if (Trigger.isInsert || Trigger.isUpdate) {
            SampleInTriggerHandler.captureStatusChangeDates(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            SampleInTriggerHandler.handleAfterInsertOrUpdate(Trigger.new);
            SampleInTriggerHandler.createSampleOutRecordsOnce(Trigger.new);
        }

        if (Trigger.isUpdate) {
            SampleInTriggerHandler.syncStatusToSampleOut(Trigger.new, Trigger.oldMap);
            SampleInTriggerHandler.handleReSamplingEmail(Trigger.new, Trigger.oldMap);
        }
        
        // Add logic to update parent Sample_In_Request__c status
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete || Trigger.isUndelete) {
            SampleInTriggerHandler.updateSampleInRequestStatus(Trigger.newMap, Trigger.oldMap);
        }
    }
}