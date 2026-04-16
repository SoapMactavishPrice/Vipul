public with sharing class AddQuoteLineItem {
    @AuraEnabled
    public static String addQuoteLineItems(Id quoteId, String jsonLineItems) {
        try {
            // Validate the Quote ID
            if (quoteId == null) {
                throw new AuraHandledException('Quote ID is required.');
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
            
            // Fetch the Quote record
            Quote quote = [
                SELECT Id, Pricebook2Id, AccountId, CurrencyIsoCode,
                Location__c, Location__r.Name
                FROM Quote 
                WHERE Id = :quoteId 
                LIMIT 1
            ];
            
            if (quote == null) {
                throw new AuraHandledException('No Quote found with the provided ID.');
            }
            
            Id warehouseId;
            
            // Decide warehouse based on Quote Location
            if (quote.Location__r != null) {
                if (quote.Location__r.Name == 'Andheri HO') {
                    warehouseId = [
                        SELECT Id FROM Unit_Master__c
                        WHERE Name = 'HO_BH_FT'
                        LIMIT 1
                    ].Id;
                } else if (quote.Location__r.Name == 'Ambernath Factory') {
                    warehouseId = [
                        SELECT Id FROM Unit_Master__c
                        WHERE Name = 'AMB_FG_M'
                        LIMIT 1
                    ].Id;
                }
            }
            
            // Assign Standard Pricebook if not assigned
            if (quote.Pricebook2Id == null) {
                Pricebook2 standardPricebook = [
                    SELECT Id FROM Pricebook2 
                    WHERE IsActive = TRUE AND IsStandard = TRUE 
                    LIMIT 1
                ];
                quote.Pricebook2Id = standardPricebook.Id;
                update quote;
            }
            
            List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
            
            // Process each line item
            for (Map<String, Object> objMap : jsList) {
                QuoteLineItem qli = new QuoteLineItem();
                qli.QuoteId = quoteId;
                qli.Warehouse__c = warehouseId;
                
                if (objMap.containsKey('prodId') && objMap.get('prodId') != null) {
                    qli.Product2Id = (Id) objMap.get('prodId');
                } else {
                    throw new AuraHandledException('Product ID is required for each line item.');
                }
                
                // Query for the Product Family based on the prodId
                Product2 product = [SELECT Family FROM Product2 WHERE Id = :qli.Product2Id LIMIT 1];
                if (product != null && String.isNotEmpty(product.Family)) {
                    qli.Product_Family__c = product.Family;
                }
                
                qli.Quality__c = (String) objMap.get('quality');
                qli.Quantity = objMap.containsKey('volume') && objMap.get('volume') != null 
                    ? Decimal.valueOf(String.valueOf(objMap.get('volume'))) 
                    : Decimal.valueOf(0);
                
                qli.Packing__c = (String) objMap.get('packaging');
                qli.Commission_Type__c = (String) objMap.get('CommissionType');
                
                // Use a helper method to safely parse decimals
                qli.Commission_Value__c = parseDecimal(objMap, 'commissionval');
                qli.Commission_Percent__c = parseDecimal(objMap, 'commissionper');
                qli.Freight_Value__c = parseDecimal(objMap, 'freightval');
                
                if (objMap.containsKey('price') && objMap.get('price') != null) {
                    qli.UnitPrice = parseDecimal(objMap, 'price');
                } else {
                    qli.UnitPrice = 0;  // Set it to null instead of 0 if it's not provided
                }
                
                // Get the Pricebook Entry
                List<PricebookEntry> pricebookEntries = [
                    SELECT Id, CurrencyIsoCode 
                    FROM PricebookEntry 
                    WHERE Pricebook2Id = :quote.Pricebook2Id 
                    AND Product2Id = :qli.Product2Id 
                    AND CurrencyIsoCode = :quote.CurrencyIsoCode 
                    LIMIT 1
                ];
                
                if (pricebookEntries.isEmpty()) {
                    throw new AuraHandledException('No Pricebook Entry found for the selected Product with matching currency.');
                }
                
                qli.PricebookEntryId = pricebookEntries[0].Id;
                quoteLineItems.add(qli);
            }
            
            // Insert Quote Line Items
            if (!quoteLineItems.isEmpty()) {
                insert quoteLineItems;
            }
            
            return 'Success';
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    // Helper method to parse decimal values safely
    private static Decimal parseDecimal(Map<String, Object> objMap, String key) {
        if (objMap.containsKey(key) && objMap.get(key) != null) {
            try {
                String value = String.valueOf(objMap.get(key));
                if (isValidDecimal(value)) {
                    return Decimal.valueOf(value);
                } else {
                    System.debug('Invalid Decimal Value: ' + value);
                    return null;
                }
            } catch (Exception e) {
                return null;
            }
        }
        return null;
    }
    
    @AuraEnabled(cacheable=true)
    public static Quote getQuoteData(Id QuoteId) {
        return [SELECT Id, Inco_Terms__c FROM Quote WHERE Id = :QuoteId LIMIT 1];
    }
    
    // Helper method to check if a string is a valid decimal
    private static Boolean isValidDecimal(String value) {
        if (String.isEmpty(value)) {
            return false;
        }
        try {
            Decimal.valueOf(value);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
    
    @AuraEnabled
    public static String checkExistingQuote(String quoteName, String accountId) {
        Quote existingQuote = [
            SELECT Id FROM Quote 
            WHERE Name = :quoteName 
            AND AccountId = :accountId 
            LIMIT 1
        ];
        return existingQuote != null ? existingQuote.Id : null;
    }
    
    @AuraEnabled
    public static String fetchAccountIdFromQuote(String quoteId) {
        // Query to fetch the AccountId related to the Quote
        Quote q = [SELECT AccountId FROM Quote WHERE Id = :quoteId LIMIT 1];
        return q.AccountId; // Return the AccountId
    }
    
    
    @AuraEnabled
    public static List<QuoteLineItem> findRecentPricesForQuote(String accountId, String productId) {
        System.debug('AccountId: ' + accountId);
        System.debug('ProductId: ' + productId);
        
        if (String.isEmpty(accountId) || String.isEmpty(productId)) {
            return new List<QuoteLineItem>();
        }
        
        List<QuoteLineItem> qliList = [
            SELECT Id, QuoteId, Product2.Name, UnitPrice, TotalPrice, Quantity, CreatedDate,
            Quote.Account.Name, Quote.Name, ListPrice, Final_Sales_Price__c
            FROM QuoteLineItem
            WHERE QuoteId IN (SELECT Id FROM Quote WHERE AccountId = :accountId)
            AND Product2Id = :productId
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
        
        System.debug('Fetched Quote Line Items: ' + qliList);
        
        return qliList;
    }
    
    @AuraEnabled
    public static Quote fetchQuoteData(Id quoteId) {
        Quote result = [SELECT Id, AccountId FROM Quote WHERE Id = :quoteId LIMIT 1];
        System.debug('Fetched Quote: ' + result);
        return result;
    }
    
    @AuraEnabled(cacheable=true)
public static String getQualityForProductFromQuote(Id quoteId, Id productId) {
    // Fetch the Quote record to get the AccountId
    Quote quote = [SELECT AccountId FROM Quote WHERE Id = :quoteId LIMIT 1];
    Id accountId = quote.AccountId;

    // Query for Sample_Out__c records that meet the criteria based on AccountId and ProductId
    List<Sample_Out__c> sampleOuts = [
        SELECT Quality__c
        FROM Sample_Out__c
        WHERE Sample_Request__r.Company_Name__c = :accountId
        AND Product_Name__c = :productId
        AND  Sample_Out_Status__c = 'Sample Approved'
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];

    // Return the Quality__c value or null if no record is found
    if (!sampleOuts.isEmpty()) {
        return sampleOuts[0].Quality__c;
    } else {
        return null;
    }
}
    
     @AuraEnabled(cacheable=true)
public static String getquoteCurrency(Id quoteId) {
    Quote quo = [SELECT CurrencyIsoCode FROM Quote WHERE Id = :quoteId LIMIT 1];
    return quo.CurrencyIsoCode;
}

}