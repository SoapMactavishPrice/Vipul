public class CompanyNameHandler {
    
    public static void updateComNameAddresses(List<Company_Name__c> newCompanyName) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> areaIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        // Collect all relevant IDs from the leads being processed
        for (Company_Name__c com : newCompanyName) {
            if (com.Pin_Code__c != null) {
                postalCodeIds.add(com.Pin_Code__c);
            }
            if (com.Area__c != null) {
                areaIds.add(com.Area__c);
            }
            if (com.City__c != null) {
                cityIds.add(com.City__c);
            }
            if (com.State__c != null) {
                stateIds.add(com.State__c);
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
        for (Company_Name__c com : newCompanyName) {
            if (com.Pin_Code__c != null && postalCodeMap.containsKey(com.Pin_Code__c)) {
                Pin_Code__c postalCode = postalCodeMap.get(com.Pin_Code__c);
                com.Area__c = postalCode.Area__c;
                com.City__c = postalCode.Area__r.City__c;
                com.State__c = postalCode.Area__r.City__r.State__c;
                com.Country__c = postalCode.Area__r.City__r.State__r.Country__c;
            } else if (com.Area__c != null && areaMap.containsKey(com.Area__c)) {
                Area__c area = areaMap.get(com.Area__c);
                com.City__c = area.City__c;
                com.State__c = area.City__r.State__c;
                com.Country__c = area.City__r.State__r.Country__c;
            } else if (com.City__c != null && cityMap.containsKey(com.City__c)) {
                City__c city = cityMap.get(com.City__c);
                com.State__c = city.State__c;
                com.Country__c = city.State__r.Country__c;
            } else if (com.State__c != null && stateMap.containsKey(com.State__c)) {
                State__c state = stateMap.get(com.State__c);
                com.Country__c = state.Country__c;
            }
        }
    }
}