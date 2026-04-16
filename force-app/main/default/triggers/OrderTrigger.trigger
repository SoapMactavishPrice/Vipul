trigger OrderTrigger on Order (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        OrderTriggerHandler.mapChecklistFields(Trigger.new);
    }
}