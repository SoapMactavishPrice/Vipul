trigger ContactInformationTrigger on Contact_Information__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ContactInformationTriggerHandler.mapCurrencyIsoCode(Trigger.new);
    }
}