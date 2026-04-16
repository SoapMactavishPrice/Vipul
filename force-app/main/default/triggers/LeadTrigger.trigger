trigger LeadTrigger on Lead (before insert, before update, after update) {
    
    if (Trigger.isBefore) {
        LeadTriggerHandler.updateLeadAddresses(Trigger.new);
        
        // Set Lead_Type__c based on User_Division__c
        LeadTriggerHandler.setLeadTypeBasedOnUserDivision(Trigger.new);
        
        if(Trigger.isUpdate){
           LeadTriggerHandler.updateTATFields(Trigger.new, Trigger.oldMap); 
        }
        
    }
    
    if (Trigger.isAfter) {
        LeadTriggerHandler.handleLeadConversion(Trigger.newMap, Trigger.oldMap);
        LeadTriggerHandler.handleLeadConversion(Trigger.new);
        LeadTriggerHandler.UpdateSampleRequestFields(Trigger.new, Trigger.oldMap);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate) {
       
        OptyTriggerHandler.convertHandler(trigger.New,Trigger.oldMap);
        LeadTriggerHandler.updateContactFieldOnOpportunity(Trigger.new);
        
        
    }
}