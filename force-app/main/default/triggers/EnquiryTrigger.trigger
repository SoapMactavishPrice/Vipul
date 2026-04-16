trigger EnquiryTrigger on Opportunity (before insert, before update, after update, after insert) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            EnquiryTriggerHandler.setContactFromAccount(Trigger.new);
        }

        if (Trigger.isUpdate) {
            //EnquiryTriggerHandler.handleProposalOpportunities(Trigger.new, Trigger.oldMap);
            //EnquiryTriggerHandler.handlePreventClose(Trigger.new, Trigger.oldMap);
            EnquiryTriggerHandler.updateStatusChange(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        EnquiryTriggerHandler.handleProposalOpportunities(Trigger.new, Trigger.oldMap);
        //EnquiryTriggerHandler.handleClosedWonOpportunities(Trigger.new, Trigger.oldMap);
        System.debug(Trigger.new);
    }
    
    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        EnquiryTriggerHandler.updateAccountIncoTerms(Trigger.new);
    }

}