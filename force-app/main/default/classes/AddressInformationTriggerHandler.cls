public class AddressInformationTriggerHandler {
    
    public static void updateAddressInformation(List<Address_Information__c> newLeads) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> areaIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();

        // Collect all relevant IDs from the leads being processed
        for (Address_Information__c lead : newLeads) {
            if (lead.Pin_Code__c != null) {
                postalCodeIds.add(lead.Pin_Code__c);
            }
            if (lead.Area__c != null) {
                areaIds.add(lead.Area__c);
            }
            if (lead.City__c != null) {
                cityIds.add(lead.City__c);
            }
            if (lead.State__c != null) {
                stateIds.add(lead.State__c);
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

        // Update the lead fields based on the selected values
        for (Address_Information__c lead : newLeads) {
            if (lead.Pin_Code__c != null && postalCodeMap.containsKey(lead.Pin_Code__c)) {
                Pin_Code__c postalCode = postalCodeMap.get(lead.Pin_Code__c);
                lead.Area__c = postalCode.Area__c;
                lead.City__c = postalCode.Area__r.City__c;
                lead.State__c = postalCode.Area__r.City__r.State__c;
                lead.Country__c = postalCode.Area__r.City__r.State__r.Country__c;
            } else if (lead.Area__c != null && areaMap.containsKey(lead.Area__c)) {
                Area__c area = areaMap.get(lead.Area__c);
                lead.City__c = area.City__c;
                lead.State__c = area.City__r.State__c;
                lead.Country__c = area.City__r.State__r.Country__c;
            } else if (lead.City__c != null && cityMap.containsKey(lead.City__c)) {
                City__c city = cityMap.get(lead.City__c);
                lead.State__c = city.State__c;
                lead.Country__c = city.State__r.Country__c;
            } else if (lead.State__c != null && stateMap.containsKey(lead.State__c)) {
                State__c state = stateMap.get(lead.State__c);
                lead.Country__c = state.Country__c;
            }
        }
    }
}    
    
    /*public static void handleCopyBillToShipTo(List<Address_Information__c> addressList) {
        // Filter addresses that require Ship To creation
        List<Address_Information__c> shipToRecords = new List<Address_Information__c>();
        Id shipToRecordTypeId = getShipToRecordTypeId();

        for (Address_Information__c address : addressList) {
            if (address.Copy_from_Bill_To_to_Ship_To__c) {
                shipToRecords.add(createShipToRecord(address, shipToRecordTypeId));
            }
        }

        // Insert Ship To records if there are any
        if (!shipToRecords.isEmpty()) {
            insert shipToRecords;
        }
    }

    // Helper method to get the Record Type ID for 'Ship_To'
    private static Id getShipToRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Address_Information__c' AND DeveloperName = 'Ship_To' LIMIT 1].Id;
    }

    // Helper method to create a Ship To record based on the Bill To record
    private static Address_Information__c createShipToRecord(Address_Information__c billTo, Id shipToRecordTypeId) {
        return new Address_Information__c(
            RecordTypeId = shipToRecordTypeId,
            Pin_Code__c = billTo.Pin_Code__c,
            Area__c = billTo.Area__c,
            City__c = billTo.City__c,
            Street__c = billTo.Street__c,
            State__c = billTo.State__c,
            Account__c = billTo.Account__c,
            Country__c = billTo.Country__c,
            GSTIN__c = billTo.GSTIN__c,
            SEZ_No__c = billTo.SEZ_No__c,
            Pan_No__c = billTo.Pan_No__c,
            GST_Type__c = billTo.GST_Type__c,
            District__c = billTo.District__c
        );
    }

}*/