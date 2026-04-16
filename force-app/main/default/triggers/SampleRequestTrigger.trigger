trigger SampleRequestTrigger on Sample_Request__c (after insert) {
    SampleRequestTriggerHandler.handleAfterInsertOrUpdate(Trigger.New);
}