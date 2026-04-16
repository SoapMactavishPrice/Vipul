trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    
    if (Trigger.isBefore) {
        System.debug('Before context');
        AccountTriggerHandler.updateAccountAddresses(Trigger.new);
        AccountTriggerHandler.populateContactDetails(Trigger.new, Trigger.oldMap);
        //AccountTriggerHandler.setSalesEmployeeCode(Trigger.new, Trigger.oldMap);
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            System.debug('After insert context');
            AccountTriggerHandler.createAddressInformation(Trigger.new);
            AccountTriggerHandler.createContacts(Trigger.new);
           // AccountTriggerHandler.handleAfterInsert(Trigger.new); // Added line to handle after insert
        }
        if (Trigger.isUpdate) {
            System.debug('After update context');
            AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
            AccountTriggerHandler.createContacts(Trigger.new); 
        }
    }
}