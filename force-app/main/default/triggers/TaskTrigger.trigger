trigger TaskTrigger on Task (after insert, after delete, after undelete) {
    System.debug('Trigger UpdateLeadStatusOnTask started');

    if (Trigger.isInsert || Trigger.isUndelete) {
        TaskTriggerHandler.updateLeadStatus(Trigger.new);
    } else if (Trigger.isDelete) {
        TaskTriggerHandler.updateLeadStatus(Trigger.old);
    }

    System.debug('Trigger UpdateLeadStatusOnTask ended');
}