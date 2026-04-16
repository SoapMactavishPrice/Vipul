trigger CaseEscalationTrigger on Case (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            for (Case c : Trigger.new) {
                if (c.Plant__c != null && c.ContactEmail != null) {
                    CaseEscalationHandler.sendEmailToContactAndPlant(c);
                }
            }
            CaseEscalationHandler.processResponsiblePersonChanges(Trigger.new, null); 
        }

        if (Trigger.isUpdate) {
            CaseEscalationHandler.sendEscalationEmails(Trigger.new, Trigger.oldMap);
            CaseEscalationHandler.sendStatusChangeEmails(Trigger.new, Trigger.oldMap); // 👈 Added this line
            CaseEscalationHandler.processResponsiblePersonChanges(Trigger.new, Trigger.oldMap);
        }
    }
}