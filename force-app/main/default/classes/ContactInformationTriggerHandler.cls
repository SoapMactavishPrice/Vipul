public class ContactInformationTriggerHandler {
    public static void mapCurrencyIsoCode(List<Contact_Information__c> contactInfoList) {
        Set<Id> leadIds = new Set<Id>();
        
        // Collect Lead Ids from Contact_Information__c records
        for (Contact_Information__c contactInfo : contactInfoList) {
            if (contactInfo.Lead__c != null) {
                leadIds.add(contactInfo.Lead__c);
            }
        }
        
        // Query Lead records to get CurrencyIsoCode
        Map<Id, Lead> leadMap = new Map<Id, Lead>([
            SELECT Id, CurrencyIsoCode 
            FROM Lead 
            WHERE Id IN :leadIds
        ]);
        
        // Map CurrencyIsoCode from Lead to Contact_Information__c
        for (Contact_Information__c contactInfo : contactInfoList) {
            if (contactInfo.Lead__c != null && leadMap.containsKey(contactInfo.Lead__c)) {
                contactInfo.CurrencyIsoCode = leadMap.get(contactInfo.Lead__c).CurrencyIsoCode;
            }
        }
    }
}