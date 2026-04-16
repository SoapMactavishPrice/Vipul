public without sharing class PurchasePriceApprovalForOpportunity {

    public OpportunityWrapper opportunity;

    public PurchasePriceApprovalForOpportunity(OpportunityWrapper opportunity) {
        this.opportunity = opportunity;
    }

    @AuraEnabled
    public static List<OpportunityWrapper> getAllOpportunities() {
        List<OpportunityLineItem> allItems = [
            SELECT Id, Product2Id, Product2.Name, OpportunityId, ListPrice, UnitPrice, Quantity,
                   Purchase_Price_in_INR__c, Purchase_Price_Status__c, Reject_Reason__c, Request_Purchase_Price__c,
                   Previous_Purchase_Price__c, Quality__c, Product2.Application__c
            FROM OpportunityLineItem
            WHERE Is_ListPrice_Zero_Unapproved__c = TRUE
        ];

        Map<Id, List<OpportunityLineItem>> oppToItemsMap = new Map<Id, List<OpportunityLineItem>>();
        Set<Id> oppIds = new Set<Id>();

        for (OpportunityLineItem item : allItems) {
            oppIds.add(item.OpportunityId);
            if (!oppToItemsMap.containsKey(item.OpportunityId)) {
                oppToItemsMap.put(item.OpportunityId, new List<OpportunityLineItem>());
            }
            oppToItemsMap.get(item.OpportunityId).add(item);
        }

        if (oppIds.isEmpty()) {
            throw new AuraHandledException('No Opportunity Line Items found with List Price = 0.');
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, Name, OwnerId, Owner.Email, Owner.Name, Link__c, Who_will_attend__c, Who_will_attend__r.Name, Who_will_attend__r.Id
             FROM Opportunity WHERE Id IN :oppIds]
        );

        List<OpportunityWrapper> wrappers = new List<OpportunityWrapper>();
        for (Id oppId : oppToItemsMap.keySet()) {
            wrappers.add(new OpportunityWrapper(oppMap.get(oppId), oppToItemsMap.get(oppId)));
        }

        return wrappers;
    }

    @AuraEnabled
    public static String updateOpportunityLineItems(String opportunityListStringObject) {
        List<OpportunityWrapper> opportunities = (List<OpportunityWrapper>) JSON.deserialize(opportunityListStringObject, List<OpportunityWrapper>.class);
        List<OpportunityLineItem> itemsToUpdate = new List<OpportunityLineItem>();

        for (OpportunityWrapper opp : opportunities) {
            Boolean shouldNotify = false;

            if (opp.updated && opp.lineItems != null) {
                for (OpportunityLineItemWrapper item : opp.lineItems) {
                    if (item.updated) {
                        OpportunityLineItem oli = new OpportunityLineItem();
                        oli.Id = item.id;
                        oli.Purchase_Price_in_INR__c = item.purchasePrice;
                        oli.Purchase_Price_Status__c = ''; // Reset status
                        itemsToUpdate.add(oli);

                        if (item.requestPurchasePrice != null) {
                            shouldNotify = true;
                        }
                    }
                }

                if (shouldNotify) {
                    SendPurchasePriceEmailAsync.sendEmailAsync(JSON.serialize(opp));
                    sendCustomNotification(opp);
                }
            }
        }

        if (!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }

        return 'Success';
    }

    private static void sendCustomNotification(OpportunityWrapper opp) {
        try {
            List<CustomNotificationType> notificationTypes = [
                SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Notification_to_Owner' LIMIT 1
            ];

            if (notificationTypes.isEmpty()) return;

            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Enquiry Purchase Price Alert');
            notification.setBody('Purchase Price has been added to the Products: ' + opp.name);
            notification.setTargetId(opp.id);
            notification.setNotificationTypeId(notificationTypes[0].Id);

            Set<String> recipientIds = new Set<String>{opp.ownerId};
            if (opp.attendeeId != null) {
                recipientIds.add(opp.attendeeId);
            }

            notification.send(recipientIds);
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }

    public class OpportunityWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String ownerId;
        @AuraEnabled public String ownerEmail;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String link;
        @AuraEnabled public String attendeeName;
        @AuraEnabled public String attendeeId;
        @AuraEnabled public List<OpportunityLineItemWrapper> lineItems;
        @AuraEnabled public Boolean updated;

        public OpportunityWrapper() {}

        public OpportunityWrapper(Opportunity opp, List<OpportunityLineItem> items) {
            this.id = opp.Id;
            this.name = opp.Name;
            this.ownerId = opp.OwnerId;
            this.ownerEmail = opp.Owner.Email;
            this.ownerName = opp.Owner.Name;
            this.link = opp.Link__c;
            this.attendeeName = opp.Who_will_attend__r != null ? opp.Who_will_attend__r.Name : null;
            this.attendeeId = opp.Who_will_attend__r != null ? opp.Who_will_attend__r.Id : null;
            this.updated = false;
            this.lineItems = new List<OpportunityLineItemWrapper>();

            for (OpportunityLineItem item : items) {
                this.lineItems.add(new OpportunityLineItemWrapper(item));
            }
        }
    }

    public class OpportunityLineItemWrapper {
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

        public OpportunityLineItemWrapper() {}

        public OpportunityLineItemWrapper(OpportunityLineItem item) {
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