trigger ContactTrigger on Contact (before insert, before update, after insert) {
    if (Trigger.isBefore) {
        ContactTriggerHandler.updateContactAddresses(Trigger.new);
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ContactTriggerHandler.handleAfterInsert(Trigger.new);
        }
    }
}