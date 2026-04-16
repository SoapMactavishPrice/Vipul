trigger CompanyBankTrigger on Company_Bank__c (before insert, before update) {
    
    if (Trigger.isBefore) {
        CompanyBankHandler.updateBankAddresses(Trigger.new);
    }

}