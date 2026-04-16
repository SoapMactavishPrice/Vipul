trigger SampleOutRequestTrigger on Sample_Out_Request__c (before insert, before update, after insert, after update) {

    // Capture dates before insert/update
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            SampleOutTriggerHandler.captureStatusChangeDates(Trigger.new, Trigger.oldMap);
        }
    } 
    // Handle after insert
    if (Trigger.isAfter && Trigger.isInsert) {
        
        // ✅ Also update parent status based on existing child records
        Set<Id> requestIds = new Set<Id>();
        for (Sample_Out_Request__c req : Trigger.new) {
            requestIds.add(req.Id);
        }
        
        SampleOutTriggerHandler.updateSampleOutRequestStatusByRequestIds(requestIds);
    }
    
    // Handle after update
    if (Trigger.isAfter && Trigger.isUpdate) {
        SampleOutRequestTriggerHandler.handleAfterUpdateOutEmail(Trigger.New, Trigger.oldMap);
        SampleOutRequestTriggerHandler.sendHOEmail(Trigger.New, Trigger.oldMap);
    }
    
}