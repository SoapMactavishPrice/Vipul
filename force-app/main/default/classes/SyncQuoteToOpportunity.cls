public class SyncQuoteToOpportunity {
    
    public String quoteId;
    List<Quote> quoteList = new List<Quote>();
    map<id, Quote> idToQuoteMap = new map<id, Quote>();
    List<id> oppIdList = new List<id>();
    List<QuoteLineItem> quoteLineList = new List<QuoteLineItem>();
    map<id, QuoteLineItem> productQuoteMap = new map<id, QuoteLineItem>();
    map<id, OpportunityLineItem> oppLineItemMap = new map<id, OpportunityLineItem>();
    List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
    
    public void SyncQuoteToOpportunity() {
        this.quoteId = ApexPages.currentPage().getParameters().get('quoteId');
        System.debug('quoteId: ' + this.quoteId);
        getQuote();
    }
    
    public PageReference getData() {
        this.quoteId = ApexPages.currentPage().getParameters().get('quoteId');
        System.debug('quoteId in getData: ' + this.quoteId);
        
        PageReference pageRef = new PageReference('/' + quoteId);
        
        getQuote();  // Get the Quote
        
        boolean isSyncAvailable = checkIsSync();
        System.debug('Is Sync Available: ' + isSyncAvailable);
        
        if (isSyncAvailable) {
            getQuoteLineItem();  // Get the QuoteLineItems
            getOppoLineItem();   // Get the OpportunityLineItems
            updateOpportunity();  // Sync Opportunity fields
            updateOpporLineItem(); // Sync OpportunityLineItem fields
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Sync Started'));
            return pageRef;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Sync is already active for this Opportunity.'));
            return pageRef;
        }
    }
    
    public void getQuote() {
        Map<String, String> s = UtilityCls.getAllFields('Quote');
        String query = 'SELECT ' + s.get('Quote') + ' FROM Quote WHERE id = :quoteId';
        System.debug('Query to fetch Quote: ' + query);
        quoteList = Database.query(query);
        
        for (Quote q : quoteList) {
            idToQuoteMap.put(q.OpportunityId, q);
            oppIdList.add(q.OpportunityId);
        }
    }
    
    public boolean checkIsSync() {
        Map<String, String> s = UtilityCls.getAllFields('Quote');
        List<Quote> q = new List<Quote>();
        
        String query = 'SELECT ' + s.get('Quote') + ' FROM Quote WHERE id != :quoteId AND OpportunityId IN :oppIdList';
        System.debug('Query to check sync: ' + query);
        q = Database.query(query);
        
        return q.isEmpty();  // If there are no quotes already synced for this opportunity, return true
    }
    
    public void getQuoteLineItem() {
        Map<String, String> s = UtilityCls.getAllFields('QuoteLineItem');
        String query = 'SELECT ' + s.get('QuoteLineItem') + ' FROM QuoteLineItem WHERE QuoteId = :quoteId';
        System.debug('Query to fetch QuoteLineItems: ' + query);
        quoteLineList = Database.query(query);
        
        for (QuoteLineItem qlin : quoteLineList) {
            productQuoteMap.put(qlin.Product2Id, qlin);
        }
    }
    
    public void getOppoLineItem() {
        Map<String, String> s = UtilityCls.getAllFields('OpportunityLineItem');
        String query = 'SELECT ' + s.get('OpportunityLineItem') + ' FROM OpportunityLineItem WHERE OpportunityId IN :oppIdList';
        System.debug('Query to fetch OpportunityLineItems: ' + query);
        oppLineItemList = Database.query(query);
        
        for (OpportunityLineItem oppLine : oppLineItemList) {
            oppLineItemMap.put(oppLine.Product2Id, oppLine);
        }
    }
    
    // Update Opportunity fields based on the Quote
    public void updateOpportunity() {
        List<Opportunity> oppoList = new List<Opportunity>();
        List<Opportunity> oppoListU = new List<Opportunity>();
        Map<String, String> s = UtilityCls.getAllFields('Opportunity');
        
        String query = 'SELECT ' + s.get('Opportunity') + ' FROM Opportunity WHERE id IN :oppIdList';
        System.debug('Query to fetch Opportunities: ' + query);
        
        oppoList = database.query(query);
        
        for (Opportunity op : oppoList) {
            Quote q = idToQuoteMap.get(op.Id);
            if (q != null) {
                System.debug('Syncing Opportunity for Quote: ' + q.Name);
                op.SyncedQuoteId = q.Id;
                op.AccountId = q.AccountId;
                op.Description = q.Description;
                op.Amount = q.GrandTotal;
                op.CurrencyIsoCode = q.CurrencyIsoCode;
                op.Enquiry_Type__c = q.Quote_Type__c; // Sync Enquiry_Type from Quote to Opportunity
                op.Inco_Terms__c = q.Inco_Terms__c;
                op.Pricebook2Id = q.Pricebook2Id;
                op.Enquiry_Type__c = q.Quote_Type__c; 
                op.Contact__c = q.ContactId;    
                op.Who_will_attend__c = q.Who_will_attend__c;    
                //   op.Contact__r.Email =    q.Email;
                //   op.Contact__r.MobilePhone = q.Phone;
                
                
                
                oppoListU.add(op);
            } else {
                System.debug('Quote not found for Opportunity: ' + op.Id);
            }
        }
        
        if (!oppoListU.isEmpty()) {
            System.debug('Updating Opportunities...');
            update oppoListU;
        } else {
            System.debug('No Opportunities to update');
        }
        
        System.debug('Updated Opportunities count: ' + oppoListU.size());
    }
    
    // Update OpportunityLineItem fields based on the QuoteLineItems
    public void updateOpporLineItem() {
        Set<Id> processedLineItems = new Set<Id>(); // Track processed OpportunityLineItems
        List<OpportunityLineItem> oppLineList1 = new List<OpportunityLineItem>();
        
        for (QuoteLineItem qli : quoteLineList) {
            OpportunityLineItem opLineItem;
            
            if (oppLineItemMap.containsKey(qli.Product2Id)) {
                opLineItem = oppLineItemMap.get(qli.Product2Id);
            } else {
                opLineItem = new OpportunityLineItem();
                opLineItem.Product2Id = qli.Product2Id;
                
                // Ensure OpportunityId is set
                if (idToQuoteMap.containsKey(quoteId)) {
                    opLineItem.OpportunityId = idToQuoteMap.get(quoteId).OpportunityId;
                } else {
                    System.debug('No Opportunity found for Quote ID: ' + quoteId);
                    continue;  // Skip this record if Opportunity is missing
                }
            }
            
            // Set fields from QuoteLineItem to OpportunityLineItem
            opLineItem.Discount = qli.Discount;
            opLineItem.Description = qli.Description;
            opLineItem.Quantity = qli.Quantity;
            opLineItem.UnitPrice = qli.UnitPrice;
            opLineItem.TotalPrice = qli.TotalPrice;
            opLineItem.Quality__c = qli.Quality__c;
            opLineItem.Packaging__c = qli.Packing__c;
            opLineItem.Packing_Type__c = qli.Packing_Type__c;
            opLineItem.Purchase_Price_in_INR__c = qli.Purchase_Price_in_INR__c;
            opLineItem.Converter__c = qli.Converter__c;
            opLineItem.Margin_Type__c = qli.Margin_Type__c;
            opLineItem.Margin_Value__c = qli.Margin_Value__c;
            opLineItem.Margin_Percent__c = qli.Margin_Percent__c;
            opLineItem.Commission_Type__c = qli.Commission_Type__c;
            opLineItem.Commission_Value__c = qli.Commission_Value__c;
            opLineItem.Commission_Percent__c = qli.Commission_Percent__c;
            opLineItem.Freight_Value__c = qli.Freight_Value__c;
            opLineItem.Product_Family__c = qli.Product_Family__c;
            opLineItem.Rejected_Purchase_Price__c = qli.Rejected_Purchase_Price__c;
            opLineItem.Reject_Reason__c = qli.Reject_Reason__c;
            opLineItem.Purchase_Price_Status__c = qli.Purchase_Price_Status__c;
            
            // Check for duplicates before adding
            if (opLineItem.Id != null && processedLineItems.contains(opLineItem.Id)) {
                System.debug('Skipping duplicate OpportunityLineItem with Id: ' + opLineItem.Id);
                continue;
            }
            
            oppLineList1.add(opLineItem);
            if (opLineItem.Id != null) {
                processedLineItems.add(opLineItem.Id);
            }
        }
        
        if (!oppLineList1.isEmpty()) {
            try {
                System.debug('Upserting OpportunityLineItems...');
                upsert oppLineList1;
            } catch (DmlException e) {
                System.debug('Error during upsert: ' + e.getMessage());
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    System.debug('Error on record ' + i + ': ' + e.getDmlMessage(i));
                }
            }
        } else {
            System.debug('No OpportunityLineItems to upsert');
        }
    }
    
}