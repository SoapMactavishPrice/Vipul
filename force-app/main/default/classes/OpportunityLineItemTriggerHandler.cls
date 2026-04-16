public class OpportunityLineItemTriggerHandler {
    
    public static Map<Id, Decimal> oldPurchasePriceMap = new Map<Id, Decimal>();
    
    public static void calculateUnitPrice(List<OpportunityLineItem> opportunityLineItems) {
        
        for (OpportunityLineItem oli : opportunityLineItems) {
            // Perform calculation only if ListPrice is 0
            if (oli.ListPrice == 0 && oli.UnitPrice ==0) {
                // Use default values to avoid null pointer exception
                Decimal convertedPurchasePrice = oli.Converted_Purchase_Price__c != null ? oli.Converted_Purchase_Price__c : 0;
                Decimal marginAmount = oli.Margin_Amount__c != null ? oli.Margin_Amount__c : 0;
                
                // Calculate the UnitPrice as convertedPurchasePrice + Margin_Amount__c
                oli.UnitPrice = convertedPurchasePrice + marginAmount; 
            }
        }
    }
    
    
    
    public static void storeOldValues(Map<Id, OpportunityLineItem> oldMap) {
        for (OpportunityLineItem oli : oldMap.values()) {
            oldPurchasePriceMap.put(oli.Id, oli.Purchase_Price_in_INR__c);
        }
    }

    public static void updatePreviousValues(Map<Id, OpportunityLineItem> newMap) {
        List<OpportunityLineItem> itemsToUpdate = new List<OpportunityLineItem>();
        
        for (OpportunityLineItem oli : newMap.values()) {
            Decimal oldPurchasePrice = oldPurchasePriceMap.get(oli.Id);

            if (oldPurchasePrice != null && oldPurchasePrice != oli.Purchase_Price_in_INR__c) {
                OpportunityLineItem oliToUpdate = new OpportunityLineItem(
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
    
    
    public static void updateSalesPriceFlag(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) return;

        // Query all line items in one go
        Map<Id, List<OpportunityLineItem>> oppIdToLineItems = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [
            SELECT OpportunityId, UnitPrice, ListPrice
            FROM OpportunityLineItem
            WHERE OpportunityId IN :opportunityIds
        ]) {
            if (!oppIdToLineItems.containsKey(oli.OpportunityId)) {
                oppIdToLineItems.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            oppIdToLineItems.get(oli.OpportunityId).add(oli);
        }

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

        for (Id oppId : opportunityIds) {
            Boolean hasLowerPrice = false;
            List<OpportunityLineItem> items = oppIdToLineItems.get(oppId);

            if (items != null) {
                for (OpportunityLineItem item : items) {
                    if (item.UnitPrice < item.ListPrice) {
                        hasLowerPrice = true;
                        break;
                    }
                }
            }

            opportunitiesToUpdate.add(new Opportunity(
                Id = oppId,
                Sales_Price_is_Less_than_List_Price__c = hasLowerPrice
            ));
        }

        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }
    
    public static void updateListPriceZeroFlag(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) return;
        
        Map<Id, List<OpportunityLineItem>> oppToLineItems = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [
            SELECT Id, OpportunityId, ListPrice, Purchase_Price_Status__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :opportunityIds
        ]) {
            if (!oppToLineItems.containsKey(oli.OpportunityId)) {
                oppToLineItems.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            oppToLineItems.get(oli.OpportunityId).add(oli);
        }
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Id oppId : oppToLineItems.keySet()) {
            Boolean hasUnapprovedZeroListPrice = false;
            
            for (OpportunityLineItem oli : oppToLineItems.get(oppId)) {
                if ((oli.ListPrice == null || oli.ListPrice == 0) &&
                    oli.Purchase_Price_Status__c != 'Approved') {
                        hasUnapprovedZeroListPrice = true;
                        break;
                    }
            }
            
            oppsToUpdate.add(new Opportunity(
                Id = oppId,
                Is_List_Price_0__c = hasUnapprovedZeroListPrice
            ));
        }
        
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }
    
}

      /*  for (OpportunityLineItem oli : opportunityLineItems) {
            // Perform calculation only if ListPrice is 0
            if (oli.ListPrice == 0) {
                // Use default values to avoid null pointer exception
                Decimal convertedPurchasePrice = oli.Converted_Purchase_Price__c != null ? oli.Converted_Purchase_Price__c : 0;
                Decimal marginPercent = oli.Margin_Percent__c != null ? oli.Margin_Percent__c : 0;
                Decimal marginValue = oli.Margin_Value__c != null ? oli.Margin_Value__c : 0;
                
                // Calculate the UnitPrice
                Decimal multiplier = marginValue != 0 ? marginValue : (marginPercent / 100);
                oli.UnitPrice = (convertedPurchasePrice + multiplier);
            }
        }	*/


		/*public static void handleApproval(List<OpportunityLineItem> newList, Map<Id, OpportunityLineItem> oldMap) {
        Set<Id> opportunityIds = new Set<Id>();
        List<FeedItem> chatterPosts = new List<FeedItem>();

        for (OpportunityLineItem oli : newList) {
            if (oli.TotalPrice < oli.UnitPrice) { // Sales Price < List Price
                oli.Approval_Status__c = 'Pending';

                // Ensure an Approver is assigned
                if (oli.Approver__c == null) {
                    oli.addError('An approver must be assigned for discount approvals.');
                }

                // Collect Opportunity IDs for chatter post
                if (oli.OpportunityId != null) {
                    opportunityIds.add(oli.OpportunityId);
                }

                // Submit for Approval
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Submitting for approval as Sales Price < List Price.');
                req.setObjectId(oli.Id);
                Approval.ProcessResult result = Approval.process(req);
            }
        }

        // Fetch Opportunity Names for Chatter Post
        if (!opportunityIds.isEmpty()) {
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
                [SELECT Id, Name FROM Opportunity WHERE Id IN :opportunityIds]
            );

            for (OpportunityLineItem oli : newList) {
                if (oppMap.containsKey(oli.OpportunityId)) {
                    String chatterMsg = 'Approval Required: Discounted price on product in Opportunity **' + oppMap.get(oli.OpportunityId).Name + '**.';
                    FeedItem post = new FeedItem();
                    post.ParentId = oli.Approver__c;
                    post.Body = chatterMsg;
                    chatterPosts.add(post);
                }
            }
        }

        if (!chatterPosts.isEmpty()) {
            insert chatterPosts;
        }
    }*/