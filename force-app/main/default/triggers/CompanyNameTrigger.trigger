trigger CompanyNameTrigger on Company_Name__c (before insert, before update) {
    
    if (Trigger.isBefore) {
        CompanyNameHandler.updateComNameAddresses(Trigger.new);
    }

}