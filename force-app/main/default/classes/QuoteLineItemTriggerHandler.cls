public class QuoteLineItemTriggerHandler {
    
    public static Map<Id, Decimal> oldPurchasePriceMap = new Map<Id, Decimal>();
    
    public static void updateDescription(List<QuoteLineItem> quoteLineItems) {
        // Collect Product2Ids from QuoteLineItems
        Set<Id> productIds = new Set<Id>();
        for (QuoteLineItem qli : quoteLineItems) {
            productIds.add(qli.Product2Id);
        }

        // Query Product2 records
        Map<Id, Product2> productMap = new Map<Id, Product2>([
            SELECT Id, Name FROM Product2 WHERE Id IN :productIds
        ]);

        // Update Description with Product2 Name
        for (QuoteLineItem qli : quoteLineItems) {
            if (productMap.containsKey(qli.Product2Id)) {
                qli.Description = productMap.get(qli.Product2Id).Name;
            }
        }
    }
    
    public static void calculateUnitPrice(List<QuoteLineItem> QuoteLineItems) {
        if (QuoteLineItems == null) {
            System.debug('QuoteLineItems is null');
            return;
        }
        
        for (QuoteLineItem qli : QuoteLineItems) {
            System.debug('Processing QuoteLineItem: ' + qli);
            System.debug('ListPrice: ' + qli.ListPrice);
            System.debug('UnitPrice: ' + qli.UnitPrice);
            
            // Perform calculation only if ListPrice is null or 0 and UnitPrice is 0
            if ((qli.ListPrice == null || qli.ListPrice == 0) && qli.UnitPrice == 0) {
                System.debug('ListPrice is null or 0 and UnitPrice is 0 for QuoteLineItem: ' + qli.Id);
                
                // Use default values to avoid null pointer exception
                Decimal convertedPurchasePrice = qli.Converted_Purchase_Price__c != null ? qli.Converted_Purchase_Price__c : 0;
                Decimal marginAmount = qli.Margin_Amount__c != null ? qli.Margin_Amount__c : 0;
                
                System.debug('Converted Purchase Price: ' + convertedPurchasePrice);
                System.debug('Margin Amount: ' + marginAmount);
                
                // Calculate the UnitPrice as convertedPurchasePrice + marginAmount
                qli.UnitPrice = convertedPurchasePrice + marginAmount;
                
                System.debug('Calculated UnitPrice: ' + qli.UnitPrice);
            } else {
                System.debug('Skipping calculation for QuoteLineItem: ' + qli.Id);
            }
        }
    }
    
    
    public static void storeOldValues(Map<Id, QuoteLineItem> oldMap) {
        for (QuoteLineItem oli : oldMap.values()) {
            oldPurchasePriceMap.put(oli.Id, oli.Purchase_Price_in_INR__c);
        }
    }

    public static void updatePreviousValues(Map<Id, QuoteLineItem> newMap) {
        List<QuoteLineItem> itemsToUpdate = new List<QuoteLineItem>();
        
        for (QuoteLineItem oli : newMap.values()) {
            Decimal oldPurchasePrice = oldPurchasePriceMap.get(oli.Id);

            if (oldPurchasePrice != null && oldPurchasePrice != oli.Purchase_Price_in_INR__c) {
                QuoteLineItem oliToUpdate = new QuoteLineItem(
                    Id = oli.Id,
                    Previous_Purchase_Price__c = oldPurchasePrice
                );
                itemsToUpdate.add(oliToUpdate);
            }
        }

        if (!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }
    }
    
    
    public static void updateSalesPriceFlag(Set<Id> quoteIds) {
        if (quoteIds == null || quoteIds.isEmpty()) return;

        // Bulk query all line items
        Map<Id, List<QuoteLineItem>> quoteIdToLineItems = new Map<Id, List<QuoteLineItem>>();
        for (QuoteLineItem qli : [
            SELECT QuoteId, UnitPrice, ListPrice
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIds
        ]) {
            if (!quoteIdToLineItems.containsKey(qli.QuoteId)) {
                quoteIdToLineItems.put(qli.QuoteId, new List<QuoteLineItem>());
            }
            quoteIdToLineItems.get(qli.QuoteId).add(qli);
        }

        List<Quote> quotesToUpdate = new List<Quote>();

        for (Id quoteId : quoteIds) {
            Boolean hasLowerPrice = false;
            List<QuoteLineItem> items = quoteIdToLineItems.get(quoteId);

            if (items != null) {
                for (QuoteLineItem item : items) {
                    if (item.UnitPrice < item.ListPrice) {
                        hasLowerPrice = true;
                        break;
                    }
                }
            }

            quotesToUpdate.add(new Quote(
                Id = quoteId,
                Sales_Price_is_Less_than_List_Price__c = hasLowerPrice
            ));
        }

        if (!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
        }
    }
    
    public static void updateListPriceZeroFlag(Set<Id> quoteIds) {
        if (quoteIds == null || quoteIds.isEmpty()) return;

        Map<Id, List<QuoteLineItem>> quoteToLineItems = new Map<Id, List<QuoteLineItem>>();
        for (QuoteLineItem qli : [
            SELECT Id, QuoteId, ListPrice, Purchase_Price_Status__c
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIds
        ]) {
            if (!quoteToLineItems.containsKey(qli.QuoteId)) {
                quoteToLineItems.put(qli.QuoteId, new List<QuoteLineItem>());
            }
            quoteToLineItems.get(qli.QuoteId).add(qli);
        }

        List<Quote> quotesToUpdate = new List<Quote>();
        for (Id quoteId : quoteToLineItems.keySet()) {
            Boolean hasZeroListPrice = false;
            for (QuoteLineItem qli : quoteToLineItems.get(quoteId)) {
                if ((qli.ListPrice == null || qli.ListPrice == 0) &&
                    qli.Purchase_Price_Status__c != 'Approved'){
                    hasZeroListPrice = true;
                    break;
                }
            }
            quotesToUpdate.add(new Quote(
                Id = quoteId,
                Is_List_Price_0__c = hasZeroListPrice
            ));
        }

        if (!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
        }
    }

}