public without sharing class PurchasePriceApprovalForQuote {

    public QuoteWrapper quote;

    public PurchasePriceApprovalForQuote(QuoteWrapper quote) {
        this.quote = quote;
    }
    
    @AuraEnabled
    public static List<QuoteWrapper> getAllQuotes() {
        List<QuoteLineItem> allItems = [
            SELECT Id, Product2Id, Product2.Name, QuoteId, ListPrice, Previous_Purchase_Price__c, Quality__c, Product2.Application__c,
            Purchase_Price_in_INR__c, Quantity, Purchase_Price_Status__c, Reject_Reason__c, Request_Purchase_Price__c, UnitPrice
            FROM QuoteLineItem 
            WHERE (ListPrice = 0 OR ListPrice = null)
            AND Purchase_Price_Status__c != 'Approved'
            
        ];
        
        Map<Id, List<QuoteLineItem>> quoteToItemsMap = new Map<Id, List<QuoteLineItem>>();
        Set<Id> quoteIds = new Set<Id>();

        for (QuoteLineItem item : allItems) {
            quoteIds.add(item.QuoteId);
            if (!quoteToItemsMap.containsKey(item.QuoteId)) {
                quoteToItemsMap.put(item.QuoteId, new List<QuoteLineItem>());
            }
            quoteToItemsMap.get(item.QuoteId).add(item);
        }

        if (quoteIds.isEmpty()) {
            throw new AuraHandledException('No Quote Line Items found with List Price = 0.');
        }

        Map<Id, Quote> quoteMap = new Map<Id, Quote>(
            [SELECT Id, Name, OwnerId, Owner.Email, Owner.Name, Link__c, Who_will_attend__c, Who_will_attend__r.Name, Who_will_attend__r.Id
             FROM Quote WHERE Id IN :quoteIds]
        );

        List<QuoteWrapper> wrappers = new List<QuoteWrapper>();
        for (Id quoteId : quoteToItemsMap.keySet()) {
            wrappers.add(new QuoteWrapper(quoteMap.get(quoteId), quoteToItemsMap.get(quoteId)));
        }

        return wrappers;
    }

    @AuraEnabled
    public static String updateQuoteLineItems(String quoteListStringObject) {
        List<QuoteWrapper> quotes = (List<QuoteWrapper>) JSON.deserialize(quoteListStringObject, List<QuoteWrapper>.class);
        List<QuoteLineItem> itemsToUpdate = new List<QuoteLineItem>();
        Set<Id> processedIds = new Set<Id>();

        for (QuoteWrapper quote : quotes) {
            Boolean shouldNotify = false;

            if (quote.updated && quote.lineItems != null) {
                for (QuoteLineItemWrapper item : quote.lineItems) {
                    if (item.updated && item.id != null && !processedIds.contains(item.id)) {
                        QuoteLineItem qli = new QuoteLineItem();
                        qli.Id = item.id;
                        qli.Purchase_Price_in_INR__c = item.purchasePrice;
                        qli.Purchase_Price_Status__c = '';
                        itemsToUpdate.add(qli);
                        processedIds.add(item.id);

                        if (item.requestPurchasePrice != null) {
                            shouldNotify = true;
                        }
                    }
                }

                if (shouldNotify) {
                    SendPurchasePriceEmailQuoteAsync.sendEmailAsync(JSON.serialize(quote));
                    sendCustomNotification(quote);
                }
            }
        }

        if (!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }

        return 'Success';
    }

    private static void sendCustomNotification(QuoteWrapper quote) {
        try {
            List<CustomNotificationType> notificationTypes = [
                SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Notification_to_Owner' LIMIT 1
            ];

            if (notificationTypes.isEmpty()) return;

            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Quote Purchase Price Alert');
            notification.setBody('Purchase Price has been added to the Products: ' + quote.name);
            notification.setTargetId(quote.id);
            notification.setNotificationTypeId(notificationTypes[0].Id);

            Set<String> recipientIds = new Set<String>{quote.ownerId};
            if (quote.attendeeId != null) {
                recipientIds.add(quote.attendeeId);
            }

            notification.send(recipientIds);
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }

    public class QuoteWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String ownerId;
        @AuraEnabled public String ownerEmail;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String link;
        @AuraEnabled public String attendeeName;
        @AuraEnabled public String attendeeId;
        @AuraEnabled public List<QuoteLineItemWrapper> lineItems;
        @AuraEnabled public Boolean updated;

        public QuoteWrapper() {}

        public QuoteWrapper(Quote quote, List<QuoteLineItem> items) {
            this.id = quote.Id;
            this.name = quote.Name;
            this.ownerId = quote.OwnerId;
            this.ownerEmail = quote.Owner.Email;
            this.ownerName = quote.Owner.Name;
            this.link = quote.Link__c;
            this.attendeeName = quote.Who_will_attend__r != null ? quote.Who_will_attend__r.Name : null;
            this.attendeeId = quote.Who_will_attend__r != null ? quote.Who_will_attend__r.Id : null;
            this.updated = false;
            this.lineItems = new List<QuoteLineItemWrapper>();

            for (QuoteLineItem item : items) {
                this.lineItems.add(new QuoteLineItemWrapper(item));
            }
        }
    }

    public class QuoteLineItemWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal purchasePrice;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String quality;
        @AuraEnabled public String application;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal previousPurchasePrice;
        @AuraEnabled public String purchasePriceStatus;
        @AuraEnabled public String rejectReason;
        @AuraEnabled public Boolean requestPurchasePrice;
        @AuraEnabled public Boolean updated;

        public QuoteLineItemWrapper() {}

        public QuoteLineItemWrapper(QuoteLineItem item) {
            this.id = item.Id;
            this.productName = item.Product2 != null ? item.Product2.Name : '';
            this.quantity = item.Quantity;
            this.quality = item.Quality__c;
            this.application = item.Product2 != null ? item.Product2.Application__c : '';
            this.listPrice = item.ListPrice;
            this.unitPrice = item.UnitPrice;
            this.previousPurchasePrice = item.Previous_Purchase_Price__c;
            this.purchasePrice = item.Purchase_Price_in_INR__c;
            this.purchasePriceStatus = item.Purchase_Price_Status__c;
            this.rejectReason = item.Reject_Reason__c;
            this.requestPurchasePrice = item.Request_Purchase_Price__c;
            this.updated = false;
        }
    }
}