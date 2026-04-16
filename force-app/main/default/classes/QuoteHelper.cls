public with sharing class QuoteHelper {
    // Fetch recent prices for a given account and product
    public static List<QuoteLineItem> findRecentPricesForQuote(Id accountId, Id productId) {
        return [
            SELECT Id, Quantity, UnitPrice 
            FROM QuoteLineItem 
            WHERE Quote.AccountId = :accountId 
            AND PricebookEntry.Product2Id = :productId 
            ORDER BY CreatedDate DESC 
            LIMIT 5
        ];
    }

    // Fetch quote details safely
    public static Quote fetchQuoteData(Id quoteId) {
        List<Quote> quotes = [
            SELECT Id, Name, Pricebook2Id 
            FROM Quote 
            WHERE Id = :quoteId 
            LIMIT 1
        ];
        return quotes.isEmpty() ? null : quotes[0];
    }

    // Get quality from Sample_Out__c based on Quote and Product
    public static String getQualityForProductFromQuote(Id quoteId, Id productId) {
        // Step 1: Get AccountId from Quote
        Quote quoteRecord = [SELECT AccountId FROM Quote WHERE Id = :quoteId LIMIT 1];
        if (quoteRecord == null || quoteRecord.AccountId == null) {
            return null;
        }

        // Step 2: Fetch Sample_Out__c record based on AccountId and ProductId
        List<Sample_Out__c> sampleOutList = [
            SELECT Quality__c 
            FROM Sample_Out__c 
            WHERE Sample_Request__c IN (
                SELECT Id FROM Sample_Request__c 
                WHERE Company_Name__c = :quoteRecord.AccountId
            ) 
            AND Product_Name__c = :productId 
            LIMIT 1
        ];

        return sampleOutList.isEmpty() ? null : sampleOutList[0].Quality__c;
    }
}