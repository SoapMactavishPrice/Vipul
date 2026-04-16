public class CompanyBankHandler {
    
    public static void updateBankAddresses(List<Company_Bank__c> newCompanyBank) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> areaIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        // Collect all relevant IDs from the leads being processed
        for (Company_Bank__c bank : newCompanyBank) {
            if (bank.Pin_Code__c != null) {
                postalCodeIds.add(bank.Pin_Code__c);
            }
            if (bank.Area__c != null) {
                areaIds.add(bank.Area__c);
            }
            if (bank.City__c != null) {
                cityIds.add(bank.City__c);
            }
            if (bank.State__c != null) {
                stateIds.add(bank.State__c);
            }
        }
        
        // Query the related records
        Map<Id, Pin_Code__c> postalCodeMap = new Map<Id, Pin_Code__c>(
            [SELECT Id, Area__c, Area__r.City__c, Area__r.City__r.State__c, Area__r.City__r.State__r.Country__c FROM Pin_Code__c WHERE Id IN :postalCodeIds]
        );
        Map<Id, Area__c> areaMap = new Map<Id, Area__c>(
            [SELECT Id, City__c, City__r.State__c, City__r.State__r.Country__c FROM Area__c WHERE Id IN :areaIds]
        );
        Map<Id, City__c> cityMap = new Map<Id, City__c>(
            [SELECT Id, State__c, State__r.Country__c FROM City__c WHERE Id IN :cityIds]
        );
        Map<Id, State__c> stateMap = new Map<Id, State__c>(
            [SELECT Id, Country__c FROM State__c WHERE Id IN :stateIds]
        );
        
        // Update the acc fields based on the selected values
        for (Company_Bank__c bank : newCompanyBank) {
            if (bank.Pin_Code__c != null && postalCodeMap.containsKey(bank.Pin_Code__c)) {
                Pin_Code__c postalCode = postalCodeMap.get(bank.Pin_Code__c);
                bank.Area__c = postalCode.Area__c;
                bank.City__c = postalCode.Area__r.City__c;
                bank.State__c = postalCode.Area__r.City__r.State__c;
                bank.Country__c = postalCode.Area__r.City__r.State__r.Country__c;
            } else if (bank.Area__c != null && areaMap.containsKey(bank.Area__c)) {
                Area__c area = areaMap.get(bank.Area__c);
                bank.City__c = area.City__c;
                bank.State__c = area.City__r.State__c;
                bank.Country__c = area.City__r.State__r.Country__c;
            } else if (bank.City__c != null && cityMap.containsKey(bank.City__c)) {
                City__c city = cityMap.get(bank.City__c);
                bank.State__c = city.State__c;
                bank.Country__c = city.State__r.Country__c;
            } else if (bank.State__c != null && stateMap.containsKey(bank.State__c)) {
                State__c state = stateMap.get(bank.State__c);
                bank.Country__c = state.Country__c;
            }
        }
    }
}