public with sharing class OpportunityLineItemController {
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityLineItems(Id opportunityId) {
        return [SELECT Id, UnitPrice, Quantity, PricebookEntry.Product2.Name, Product2Id, ListPrice, Purchase_Price_in_INR__c, Converter__c, Margin_Type__c, 
                Margin_Value__c, Margin_Percent__c, Commission_Type__c, Commission_Value__c,Quality__c, Commission_Percent__c, Freight_Value__c, Product2.Name,
                Final_Price__c, Total_Price_with_Inco_Terms__c,Converted_Purchase_Price__c,Commission_Amount__c,Opportunity.Inco_Terms__c,Rejected_Purchase_Price__c,
                Reject_Reason__c,Purchase_Price_Status__c,Total_Price__c, Packaging__c
                FROM OpportunityLineItem WHERE OpportunityId = :opportunityId];
    }

    @AuraEnabled
    public static void updateOpportunityLineItems(List<OpportunityLineItem> lineItems) {
        update lineItems;
    }
    
     @AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> getQuoteLineItems(Id QuoteId) {
        return [SELECT Id, UnitPrice, Quantity, PricebookEntry.Product2.Name, Product2Id, ListPrice, Purchase_Price_in_INR__c, Converter__c, Margin_Type__c, 
                Margin_Value__c, Margin_Percent__c, Commission_Type__c, Commission_Value__c,Quality__c, Commission_Percent__c, Freight_Value__c, Product2.Name,
                Final_Sales_Price__c, Sales_Price_with_Inco_Terms__c,Converted_Purchase_Price__c,Commission_Amount__c,Quote.Inco_Terms__c,Rejected_Purchase_Price__c,
                Reject_Reason__c,Purchase_Price_Status__c,Total_Price__c, Packing__c
                FROM QuoteLineItem WHERE QuoteId = :QuoteId];
    }
    
    @AuraEnabled
    public static void updateQuoteLineItems(List<QuoteLineItem> lineItems) {
        update lineItems;
    }
    
     @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderItems(Id OrderId) {
        return [SELECT Id, UnitPrice, Quantity, PricebookEntry.Product2.Name, Product2Id, ListPrice, Purchase_Price_in_INR__c, Converter__c, Margin_Type__c, 
                Margin_Value__c, Margin_Percent__c, Commission_Type__c, Commission_Value__c,Quality__c, Commission_Percent__c, Freight_Value__c, Product2.Name,
                Final_Sales_Price__c, Sales_Price_with_Inco_Terms__c,Converted_Purchase_Price__c,Commission_Amount__c,Order.Inco_Terms__c,Rejected_Purchase_Price__c,
                Reject_Reason__c,Purchase_Price_Status__c,Total_Price__c, Packaging__c
                FROM OrderItem WHERE OrderId = :OrderId];
    }
    
    @AuraEnabled
    public static void updateOrderItems(List<OrderItem> lineItems) {
        update lineItems;
    }
}