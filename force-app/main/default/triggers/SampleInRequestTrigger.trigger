trigger SampleInRequestTrigger on Sample_In_Request__c (
    before insert, before update,
    after insert, after update
) {

    if (Trigger.isBefore) {
        SampleInRequestTriggerHandler.captureStatusDates(
            Trigger.new,
            Trigger.oldMap
        );
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        Set<Id> requestIds = new Set<Id>();
        for (Sample_In_Request__c req : Trigger.new) {
            requestIds.add(req.Id);
        }
        SampleInTriggerHandler.updateSampleInRequestStatusByRequestIds(requestIds);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        SampleInRequestTriggerHandler.handleAfterUpdateEmail(
            Trigger.new,
            Trigger.oldMap
        );
        SampleInRequestTriggerHandler.sendHOEmail(
            Trigger.new,
            Trigger.oldMap
        );
    }
}