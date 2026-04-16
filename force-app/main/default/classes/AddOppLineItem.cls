public with sharing class AddOppLineItem {

    @AuraEnabled
    public static String addOpportunityLineItems(Id opportunityId, String jsonLineItems) {
        try {
            // Validate the Opportunity ID
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity ID is required.');
            }

            // Debug received JSON input
            System.debug('Received JSON String: ' + jsonLineItems);

            // Ensure the JSON input is not null or empty
            if (String.isEmpty(jsonLineItems) || jsonLineItems == '[]') {
                throw new AuraHandledException('Invalid or empty JSON input.');
            }

            // Deserialize JSON safely
            Object rawData = JSON.deserializeUntyped(jsonLineItems);
            System.debug('Deserialized Data: ' + rawData);

            List<Map<String, Object>> jsList = new List<Map<String, Object>>();

            // Ensure the data is a list before casting
            if (rawData instanceof List<Object>) {
                List<Object> tempList = (List<Object>) rawData;
                for (Object item : tempList) {
                    if (item instanceof Map<String, Object>) {
                        jsList.add((Map<String, Object>) item);
                    }
                }
            } else {
                throw new AuraHandledException('Invalid JSON format. Expected a list of objects.');
            }

            System.debug('Parsed Line Items: ' + jsList);

            // Fetch the Opportunity record
            Opportunity opp = [
                SELECT Id, Pricebook2Id, AccountId, CurrencyIsoCode,Inco_Terms__c,Enquiry_Type__c 
                FROM Opportunity 
                WHERE Id = :opportunityId 
                LIMIT 1
            ];
            
            if (opp == null) {
                throw new AuraHandledException('No Opportunity found with the provided ID.');
            }
            
           /* //  Validate Inco Terms
            if (String.isEmpty(opp.Inco_Terms__c)) {
                throw new AuraHandledException('Inco Terms must be specified on the Opportunity before adding line items.');
            }*/
            
            // Assign Standard Pricebook if not assigned
            if (opp.Pricebook2Id == null) {
                Pricebook2 standardPricebook = [
                    SELECT Id FROM Pricebook2 
                    WHERE IsActive = TRUE AND IsStandard = TRUE 
                    LIMIT 1
                ];
                opp.Pricebook2Id = standardPricebook.Id;
                update opp;
            }

            List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();

            // Process each line item
            for (Map<String, Object> objMap : jsList) {
                OpportunityLineItem oli = new OpportunityLineItem();
                oli.OpportunityId = opportunityId;

                if (objMap.containsKey('prodId') && objMap.get('prodId') != null) {
                    oli.Product2Id = (Id) objMap.get('prodId');
                } else {
                    throw new AuraHandledException('Product ID is required for each line item.');
                }

                // Query for the Product Family based on the prodId
                Product2 product = [SELECT Family FROM Product2 WHERE Id = :oli.Product2Id LIMIT 1];
                if (product != null && String.isNotEmpty(product.Family)) {
                    oli.Product_Family__c = product.Family;
                }

                oli.Quality__c = (String) objMap.get('quality');
                oli.Quantity = objMap.containsKey('volume') && objMap.get('volume') != null 
                    ? Decimal.valueOf(String.valueOf(objMap.get('volume'))) 
                    : Decimal.valueOf(0);

                oli.Packaging__c = (String) objMap.get('packaging');
                oli.Commission_Type__c = (String) objMap.get('CommissionType');

                // Safely parse Commission Value and Commission Percent
                try {
                oli.Commission_Value__c = objMap.containsKey('commissionval') && objMap.get('commissionval') != null ? 
                    Decimal.valueOf((String) objMap.get('commissionval')) : null;
            } catch (Exception e) {
                oli.Commission_Value__c = null; 
                System.debug('Invalid Commission Value: ' + objMap.get('commissionval') + ' Error: ' + e.getMessage());
            }
            
            // Handle commission percentage
            try {
                oli.Commission_Percent__c = objMap.containsKey('commissionper') && objMap.get('commissionper') != null ? 
                    Decimal.valueOf((String) objMap.get('commissionper')) : null;
            } catch (Exception e) {
                oli.Commission_Percent__c = null; 
                System.debug('Invalid Commission Percent: ' + objMap.get('commissionper') + ' Error: ' + e.getMessage());
            }
                oli.UnitPrice = parseDecimal(objMap, 'price') != null ? parseDecimal(objMap, 'price') : 0;

                // Handling Freight Value safely
                oli.Freight_Value__c = parseDecimal(objMap, 'freightval');

                // Get the Pricebook Entry based on Opportunity's currency
                List<PricebookEntry> pricebookEntries = [
                    SELECT Id, UnitPrice 
                    FROM PricebookEntry 
                    WHERE Pricebook2Id = :opp.Pricebook2Id 
                    AND Product2Id = :oli.Product2Id 
                    AND CurrencyIsoCode = :opp.CurrencyIsoCode 
                    LIMIT 1
                ];
                
                System.debug('Pricebook Entries: ' + pricebookEntries);

                if (pricebookEntries.isEmpty()) {
                    throw new AuraHandledException('No Pricebook Entry found for the selected Product and Opportunity Currency.');
                }

                oli.PricebookEntryId = pricebookEntries[0].Id;
                
                System.debug('Opportunity Line Item (oli) after setting PricebookEntryId: ' + oli);
                
                lineItems.add(oli);
                
                System.debug('Line Items: ' + lineItems);

            }

            // Insert Opportunity Line Items
            if (!lineItems.isEmpty()) {
                insert lineItems;
            }

            return 'Success';
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    // Helper method to safely parse decimal values
    private static Decimal parseDecimal(Map<String, Object> objMap, String key) {
        if (objMap.containsKey(key) && objMap.get(key) != null) {
            String value = String.valueOf(objMap.get(key)).trim();
            if (String.isNotEmpty(value)) {
                try {
                    return Decimal.valueOf(value);
                } catch (Exception e) {
                    System.debug('Invalid Decimal value for ' + key + ': ' + value + ' Error: ' + e.getMessage());
                    return null;
                }
            }
        }
        return null;
    }
    
    @AuraEnabled(cacheable=true)
public static Opportunity getOpportunityData(Id opportunityId) {
    Opportunity opp = [SELECT Id, Inco_Terms__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];

    // Debug the entire opportunity record
    System.debug('Fetched Opportunity: ' + opp);

    // Debug just the Inco_Terms__c field
    System.debug('Inco Terms: ' + opp.Inco_Terms__c);

    return opp;
}


    @AuraEnabled
    public static String checkExistingOpportunity(String opportunityName, String accountId) {
        try {
            // Query for the Opportunity with the given Name and AccountId
            Opportunity existingOpp = [
                SELECT Id 
                FROM Opportunity 
                WHERE Name = :opportunityName 
                AND AccountId = :accountId 
                LIMIT 1
            ];

            // If an Opportunity is found, return its Id, otherwise return null
            if (existingOpp != null) {
                return existingOpp.Id;
            } else {
                return null;  // No Opportunity found
            }
        } catch (Exception e) {
            // Catch any exceptions and return a descriptive error message
            System.debug('Error occurred while checking existing Opportunity: ' + e.getMessage());
            throw new AuraHandledException('Error occurred while checking for existing Opportunity: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled(cacheable=true)
public static List<OpportunityLineItem> findRecentPrices(String accountId, String productId) {
    if (String.isEmpty(accountId) || String.isEmpty(productId)) {
        return new List<OpportunityLineItem>();
    }
    
    // Query to fetch the last 5 prices for the given account and product
    List<OpportunityLineItem> oliList = [
        SELECT Id, OpportunityId, Product2.Name, UnitPrice, TotalPrice, Quantity, CreatedDate,
            Opportunity.Account.Name, Opportunity.Name, ListPrice, Final_Price__c
        FROM OpportunityLineItem
        WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE AccountId = :accountId)
        AND Product2Id = :productId
        ORDER BY CreatedDate DESC
        LIMIT 5
    ];
    
    return oliList;
}
  @AuraEnabled
    public static Opportunity fetchOpportunityData(Id opportunityId) {
        // Query to get the Opportunity record and its AccountId
        return [SELECT Id, AccountId FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
    }
    
@AuraEnabled(cacheable=true)
public static String getQualityForProduct(Id opportunityId, Id productId, Id accountId) {
    // Query for Sample_Out__c records that meet the criteria
    List<Sample_Out__c> sampleOuts = [
        SELECT Quality__c
        FROM Sample_Out__c
        WHERE Sample_Request__r.Enquiry__c = :opportunityId
        AND Sample_Request__r.Company_Name__c = :accountId
        AND Product_Name__c = :productId
        AND Sample_Out_Status__c = 'Sample Approved'
        ORDER BY CreatedDate DESC 
        LIMIT 1
    ];
    
    // Check if there are any records returned
    if (!sampleOuts.isEmpty()) {
        // Return the quality of the first record if available
        return sampleOuts[0].Quality__c;
    } else {
        // Return null or a default value if no records were found
        System.debug('No sample found for the given criteria');
        return null;  // You could also return 'STD' or some other default value
    }
}

    @AuraEnabled(cacheable=true)
public static String getenquiryCurrency(Id enquiryId) {
    Opportunity opp = [SELECT CurrencyIsoCode FROM Opportunity WHERE Id = :enquiryId LIMIT 1];
    return opp.CurrencyIsoCode;
}


}