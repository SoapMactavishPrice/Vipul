public class EnquiryTriggerHandler {
    
    // Scenario 1: Create Quote and Quote Line Item When Opportunity is Proposal.
    
    public static void handleProposalOpportunities(
    List<Opportunity> newList,
    Map<Id, Opportunity> oldMap
) {
    /* -----------------------------
       Collect Opportunity Ids
       ----------------------------- */
    Set<Id> opportunityIds = new Set<Id>();
    for (Opportunity opp : newList) {
        opportunityIds.add(opp.Id);
    }

    /* -----------------------------
       Existing Quote count
       ----------------------------- */
    Map<Id, Integer> quoteCountMap = new Map<Id, Integer>();
    for (AggregateResult ar : [
        SELECT OpportunityId, COUNT(Id) cnt
        FROM Quote
        WHERE OpportunityId IN :opportunityIds
        GROUP BY OpportunityId
    ]) {
        quoteCountMap.put((Id) ar.get('OpportunityId'), (Integer) ar.get('cnt'));
    }

    /* -----------------------------
       Opportunity Line Items
       ----------------------------- */
    Map<Id, List<OpportunityLineItem>> oppToOLIs = new Map<Id, List<OpportunityLineItem>>();
    for (OpportunityLineItem oli : [
        SELECT OpportunityId, Product2Id, Quantity, UnitPrice, PricebookEntryId,
               Quality__c, Packaging__c, Packing_Type__c,
               Purchase_Price_in_INR__c, Converter__c,
               Margin_Type__c, Margin_Value__c, Margin_Percent__c,
               Commission_Type__c, Commission_Value__c, Commission_Percent__c,
               Freight_Value__c, Product_Family__c,
               Rejected_Purchase_Price__c, Reject_Reason__c,
               Purchase_Price_Status__c, Request_Purchase_Price__c
        FROM OpportunityLineItem
        WHERE OpportunityId IN :opportunityIds
    ]) {
        if (!oppToOLIs.containsKey(oli.OpportunityId)) {
            oppToOLIs.put(oli.OpportunityId, new List<OpportunityLineItem>());
        }
        oppToOLIs.get(oli.OpportunityId).add(oli);
    }

    /* -----------------------------
       Record Types
       ----------------------------- */
    Map<Id, String> oppRTIdToName = new Map<Id, String>();
    for (RecordType rt : [
        SELECT Id, DeveloperName
        FROM RecordType
        WHERE SObjectType = 'Opportunity'
    ]) {
        oppRTIdToName.put(rt.Id, rt.DeveloperName);
    }

    Map<String, Id> quoteRTByName = new Map<String, Id>();
    for (RecordType rt : [
        SELECT Id, DeveloperName
        FROM RecordType
        WHERE SObjectType = 'Quote'
    ]) {
        quoteRTByName.put(rt.DeveloperName, rt.Id);
    }

    /* -----------------------------
       Opportunities
       ----------------------------- */
    List<Opportunity> opps = [
        SELECT Id, Name, StageName, Pricebook2Id, Enquiry_Type__c,
               Contact__c, Contact__r.Email, Contact__r.MobilePhone,
               AccountId, Account.Payment_Terms__c, Account.Customer_Code__c,
               CurrencyIsoCode, Description, Inco_Terms__c,
               Who_will_attend__c, RecordTypeId, OwnerId,
               Sales_Price_is_Less_than_List_Price__c, Is_List_Price_0__c
        FROM Opportunity
        WHERE Id IN :opportunityIds
    ];

    /* -----------------------------
       Address Records
       ----------------------------- */
    Map<String, Id> addrRT = new Map<String, Id>();
    
    Map<String, Schema.RecordTypeInfo> rtInfoMap =
        Schema.SObjectType.Address_Information__c.getRecordTypeInfosByDeveloperName();
    
    if (rtInfoMap.containsKey('Bill_To')) {
        addrRT.put('Bill_To', rtInfoMap.get('Bill_To').getRecordTypeId());
    }
    if (rtInfoMap.containsKey('Ship_To')) {
        addrRT.put('Ship_To', rtInfoMap.get('Ship_To').getRecordTypeId());
    }

    Set<Id> accountIds = new Set<Id>();
    for (Opportunity o : opps) {
        if (o.AccountId != null) accountIds.add(o.AccountId);
    }

    Map<Id, Address_Information__c> billToMap = new Map<Id, Address_Information__c>();
    Map<Id, Address_Information__c> shipToMap = new Map<Id, Address_Information__c>();

    for (Address_Information__c a : [
        SELECT Id, Account__c, RecordTypeId
        FROM Address_Information__c
        WHERE Account__c IN :accountIds
          AND RecordTypeId IN :new List<Id>{
              addrRT.get('Bill_To'),
              addrRT.get('Ship_To')
          }
    ]) {
        if (a.RecordTypeId == addrRT.get('Bill_To')) {
            billToMap.put(a.Account__c, a);
        } else {
            shipToMap.put(a.Account__c, a);
        }
    }

    /* -----------------------------
       Location & Warehouse Masters
       ----------------------------- */
    Map<String, Id> locationByName = new Map<String, Id>();
    for (Location__c l : [
        SELECT Id, Name
        FROM Location__c
        WHERE Name IN ('Andheri HO', 'Ambernath Factory')
    ]) {
        locationByName.put(l.Name, l.Id);
    }

    Map<String, Id> warehouseByName = new Map<String, Id>();
    for (Unit_Master__c u : [
        SELECT Id, Name
        FROM Unit_Master__c
        WHERE Name IN ('HO_BH_FT', 'AMB_FG_M')
    ]) {
        warehouseByName.put(u.Name, u.Id);
    }

    /* -----------------------------
       Create Quotes
       ----------------------------- */
    List<Quote> quotesToInsert = new List<Quote>();
    Map<Id, String> oppIdToRTName = new Map<Id, String>();

    for (Opportunity opp : opps) {
        if (opp.StageName == 'Proposal'
            && oldMap.containsKey(opp.Id)
            && opp.StageName != oldMap.get(opp.Id).StageName
            && (!quoteCountMap.containsKey(opp.Id) || quoteCountMap.get(opp.Id) == 0)
        ) {
            String rtName = oppRTIdToName.get(opp.RecordTypeId);
            oppIdToRTName.put(opp.Id, rtName);

            Id locationId =
                rtName == 'International'
                    ? locationByName.get('Andheri HO')
                    : locationByName.get('Ambernath Factory');

            quotesToInsert.add(new Quote(
                OpportunityId = opp.Id,
                Name = opp.Name + ' - Proposal',
                OwnerId = opp.OwnerId,
                Pricebook2Id = opp.Pricebook2Id,
                Status = 'Draft',
                ExpirationDate = Date.today().addDays(30),
                Validity__c = Date.today().addDays(15),
                Quote_Type__c = opp.Enquiry_Type__c,
                ContactId = opp.Contact__c,
                CurrencyIsoCode = opp.CurrencyIsoCode,
                Description = opp.Description,
                Inco_Terms__c = opp.Inco_Terms__c,
                RecordTypeId = quoteRTByName.get(rtName),
                Who_will_attend__c = opp.Who_will_attend__c,
                Email = opp.Contact__r.Email,
                Phone = opp.Contact__r.MobilePhone,
                Payment_Terms__c = opp.Account.Payment_Terms__c,
                Customer_Code__c = opp.Account.Customer_Code__c,
                Sales_Price_is_Less_than_List_Price__c =
                    opp.Sales_Price_is_Less_than_List_Price__c,
                Is_List_Price_0__c = opp.Is_List_Price_0__c,
                Consignee_Address1__c =
                    billToMap.containsKey(opp.AccountId)
                        ? billToMap.get(opp.AccountId).Id
                        : null,
                Delivery_Address1__c =
                    shipToMap.containsKey(opp.AccountId)
                        ? shipToMap.get(opp.AccountId).Id
                        : null,
                Port_of_Loading__c = 'Any Indian Port',
                Location__c = locationId
            ));
        }
    }

    if (quotesToInsert.isEmpty()) return;

    insert quotesToInsert;

    /* -----------------------------
       Create Quote Line Items
       ----------------------------- */
    Map<Id, Id> oppToQuote = new Map<Id, Id>();
    for (Quote q : quotesToInsert) {
        oppToQuote.put(q.OpportunityId, q.Id);
    }

    List<QuoteLineItem> qlisToInsert = new List<QuoteLineItem>();

    for (Id oppId : oppToQuote.keySet()) {
        String rtName = oppIdToRTName.get(oppId);
        Id warehouseId =
            rtName == 'International'
                ? warehouseByName.get('HO_BH_FT')
                : warehouseByName.get('AMB_FG_M');

        if (!oppToOLIs.containsKey(oppId)) continue;

        for (OpportunityLineItem oli : oppToOLIs.get(oppId)) {
            qlisToInsert.add(new QuoteLineItem(
                QuoteId = oppToQuote.get(oppId),
                Product2Id = oli.Product2Id,
                Quantity = oli.Quantity,
                UnitPrice = oli.UnitPrice,
                PricebookEntryId = oli.PricebookEntryId,
                Warehouse__c = warehouseId,
                Quality__c = oli.Quality__c,
                Packing__c = oli.Packaging__c,
                Packing_Type__c = oli.Packing_Type__c,
                Purchase_Price_in_INR__c = oli.Purchase_Price_in_INR__c,
                Converter__c = oli.Converter__c,
                Margin_Type__c = oli.Margin_Type__c,
                Margin_Value__c = oli.Margin_Value__c,
                Margin_Percent__c = oli.Margin_Percent__c,
                Commission_Type__c = oli.Commission_Type__c,
                Commission_Value__c = oli.Commission_Value__c,
                Commission_Percent__c = oli.Commission_Percent__c,
                Freight_Value__c = oli.Freight_Value__c,
                Product_Family__c = oli.Product_Family__c,
                Rejected_Purchase_Price__c = oli.Rejected_Purchase_Price__c,
                Reject_Reason__c = oli.Reject_Reason__c,
                Purchase_Price_Status__c = oli.Purchase_Price_Status__c,
                Request_Purchase_Price__c = oli.Request_Purchase_Price__c
            ));
        }
    }

    if (!qlisToInsert.isEmpty()) {
        insert qlisToInsert;
    }
}


    
    /*
    public static void handleClosedWonOpportunities(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        // Collect Opportunity IDs for bulk queries
        Set<Id> opportunityIds = new Set<Id>();
        for (Opportunity opp : newList) {
            opportunityIds.add(opp.Id);
        }
        
        // Query existing Orders and Opportunity Line Items
        Map<Id, Order> existingOrdersMap = new Map<Id, Order>(
            [SELECT Id, OpportunityId FROM Order WHERE OpportunityId IN :opportunityIds]
        );
        
        Map<Id, List<OpportunityLineItem>> opportunityLineItemsMap = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [
            SELECT OpportunityId, Product2Id, Quantity, UnitPrice, PricebookEntryId, TotalPrice, Quality__c, Packing_Type__c, Description, ProductCode, GST__c,
            Purchase_Price_in_INR__c, Converter__c,
            Margin_Type__c, Margin_Value__c, Margin_Percent__c, Commission_Type__c, Commission_Value__c, Commission_Percent__c, Freight_Value__c, Product_Family__c,
            Rejected_Purchase_Price__c, Reject_Reason__c, Purchase_Price_Status__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :opportunityIds
        ]) {
            if (!opportunityLineItemsMap.containsKey(oli.OpportunityId)) {
                opportunityLineItemsMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            opportunityLineItemsMap.get(oli.OpportunityId).add(oli);
        }
        
        // Query related Quotes and create a map of OpportunityId to Quote
        Map<Id, Quote> opportunityToQuoteMap = new Map<Id, Quote>();
        for (Quote quote : [
            SELECT OpportunityId, PO_PI_Number__c, PO_Date__c 
            FROM Quote 
            WHERE OpportunityId IN :opportunityIds
        ]) {
            opportunityToQuoteMap.put(quote.OpportunityId, quote);
        }
        
        // Debugging: Check if Quotes are fetched correctly
        System.debug('Fetched Quotes: ' + opportunityToQuoteMap);
        
        // Prepare lists for bulk DML operations
        List<Order> ordersToInsert = new List<Order>();
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        
        // Loop through opportunities
        for (Opportunity opp : newList) {
            System.debug('Processing Opportunity: ' + opp.Id + ', Stage: ' + opp.StageName);
            
            // Check if StageName is 'Closed Won', has changed, and there are no existing orders
            if (opp.StageName == 'Closed Won'
                && oldMap.containsKey(opp.Id)
                && opp.StageName != oldMap.get(opp.Id).StageName
                && !existingOrdersMap.containsKey(opp.Id)) {
                    
                    System.debug('Opportunity meets criteria for Closed Won and no existing orders.');
                    
                    // Validation: Ensure the Opportunity has Opportunity Line Items
                    if (!opp.HasOpportunityLineItem) {
                        opp.addError('Please add at least one product before changing the stage to Closed Won.');
                        continue;
                    }
                    
                    System.debug('Opportunity has Opportunity Line Items.');
                    
                    // Validation: Ensure the related Quote has PO_PI_Number__c and PO_Date__c
                    if (opportunityToQuoteMap.containsKey(opp.Id)) {
                        Quote relatedQuote = opportunityToQuoteMap.get(opp.Id);
                        System.debug('Related Quote: ' + relatedQuote);
                        System.debug('PO_PI_Number__c: ' + relatedQuote.PO_PI_Number__c);
                        System.debug('PO_Date__c: ' + relatedQuote.PO_Date__c);
                        if (relatedQuote.PO_PI_Number__c == null || relatedQuote.PO_Date__c == null) {
                            opp.addError('Please fill in the PO/PI Number and PO Date in the related Quote before marking the Opportunity as Closed Won.');
                            continue;
                        }
                        System.debug('Related Quote has required fields.');
                    } else {
                        System.debug('No related Quote found for Opportunity: ' + opp.Id);
                        opp.addError('No related Quote found. Please ensure a Quote is created and linked to this Opportunity.');
                        continue;
                    }
                    
                    // Create a new Order
                    Order newOrder = new Order(
                        OpportunityId = opp.Id,
                        AccountId = opp.AccountId,
                        Pricebook2Id = opp.Pricebook2Id, // Set the Price Book from Opportunity
                        EffectiveDate = Date.today(),
                        Status = 'Draft', // Adjust as per your business process
                        Inco_Terms__c = opp.Inco_Terms__c,
                        CurrencyIsoCode = opp.CurrencyIsoCode,
                        Description = opp.Description,
                        Order_Type__c = opp.Enquiry_Type__c,
                        Consignee_Address__c = opp.AccountId
                    );
                    ordersToInsert.add(newOrder);
                }
        }
        
        // Insert Orders in bulk
        if (!ordersToInsert.isEmpty()) {
            insert ordersToInsert;
            
            // Map OpportunityId to newly created Orders
            Map<Id, Id> oppToOrderMap = new Map<Id, Id>();
            for (Order order : ordersToInsert) {
                oppToOrderMap.put(order.OpportunityId, order.Id);
            }
            
            // Create Order Items for each Opportunity with products
            for (Id oppId : oppToOrderMap.keySet()) {
                if (opportunityLineItemsMap.containsKey(oppId)) {
                    Id orderId = oppToOrderMap.get(oppId);
                    for (OpportunityLineItem oli : opportunityLineItemsMap.get(oppId)) {
                        OrderItem newOrderItem = new OrderItem(
                            OrderId = orderId,
                            Product2Id = oli.Product2Id,
                            Quantity = oli.Quantity,
                            UnitPrice = oli.UnitPrice,
                            PricebookEntryId = oli.PricebookEntryId,
                            Quality__c = oli.Quality__c,
                            //Packaging_Quantity__c = oli.Packaging__c,
                            Packing_Type__c = oli.Packing_Type__c,
                            Description = oli.Description,
                            Product_Code__c = oli.ProductCode,
                            GST__c = oli.GST__c,
                            Purchase_Price_in_INR__c = oli.Purchase_Price_in_INR__c,
                            Converter__c = oli.Converter__c,
                            Margin_Type__c = oli.Margin_Type__c,
                            Margin_Value__c = oli.Margin_Value__c,
                            Margin_Percent__c = oli.Margin_Percent__c,
                            Commission_Type__c = oli.Commission_Type__c,
                            Commission_Value__c = oli.Commission_Value__c,
                            Commission_Percent__c = oli.Commission_Percent__c,
                            Freight_Value__c = oli.Freight_Value__c,
                            Rejected_Purchase_Price__c = oli.Rejected_Purchase_Price__c,
                            Reject_Reason__c = oli.Reject_Reason__c,
                            Purchase_Price_Status__c = oli.Purchase_Price_Status__c
                            
                        );
                        orderItemsToInsert.add(newOrderItem);
                    }
                }
            }
            
            // Insert Order Items in bulk
            if (!orderItemsToInsert.isEmpty()) {
                insert orderItemsToInsert;
            }
        }
    }
    */
    
    public static void updateAccountIncoTerms(List<Opportunity> oppList) {
        // Map to hold AccountId to Opportunity Inco_Terms__c
        Map<Id, String> accountToOppIncoTermsMap = new Map<Id, String>();
        
        for (Opportunity opp : oppList) {
            if (opp.AccountId != null && opp.Inco_Terms__c != null) {
                accountToOppIncoTermsMap.put(opp.AccountId, opp.Inco_Terms__c);
            }
        }
        
        if (!accountToOppIncoTermsMap.isEmpty()) {
            // Query existing Account Inco_Terms__c values
            Map<Id, Account> existingAccounts = new Map<Id, Account>(
                [SELECT Id, Inco_Terms__c FROM Account WHERE Id IN :accountToOppIncoTermsMap.keySet()]
            );
            
            List<Account> accountsToUpdate = new List<Account>();
            
            for (Id accId : accountToOppIncoTermsMap.keySet()) {
                Account existingAcc = existingAccounts.get(accId);
                String oppIncoTerm = accountToOppIncoTermsMap.get(accId);
                
                // Only update if the values are different
                if (existingAcc != null && oppIncoTerm != existingAcc.Inco_Terms__c) {
                    existingAcc.Inco_Terms__c = oppIncoTerm;
                    accountsToUpdate.add(existingAcc);
                }
            }
            
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
        }
    }
    
    
    public static void setContactFromAccount(List<Opportunity> oppList) {
        Set<Id> accountIds = new Set<Id>();

        // Collect AccountIds from Opportunities
        for (Opportunity opp : oppList) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }

        // Query Accounts with Contact__c
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Contact__c FROM Account WHERE Id IN :accountIds]
        );

        // Map Contact__c from Account to Opportunity
        for (Opportunity opp : oppList) {
            if (opp.AccountId != null && accountMap.containsKey(opp.AccountId)) {
                opp.Contact__c = accountMap.get(opp.AccountId).Contact__c;
            }
        }
    }
    
    
    /*public static void handlePreventClose(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        Set<Id> oppIds = new Set<Id>();
        
        for (Opportunity opp : newList) {
            if (opp.StageName == 'Closed Won' || opp.StageName == 'Closed Lost') {
                oppIds.add(opp.Id);
            }
        }
        
        if (!oppIds.isEmpty()) {
            Integer pendingCount = [SELECT COUNT() FROM OpportunityLineItem 
                                    WHERE OpportunityId IN :oppIds AND Approval_Status__c = 'Pending'];
            
            if (pendingCount > 0) {
                for (Opportunity opp : newList) {
                    opp.addError('Cannot close Opportunity while discounted line items are pending approval.');
                }
            }
        }
    } */
    
   
    public static void updateStatusChange(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
		Map<String, String> statusFieldMap = new Map<String, String>{
                'New' => 'New_Capture_Date_Time__c',
                'Proposal' => 'Proposal_Capture_Date_Time__c',
                'Sample Sent' => 'Sample_Capture_Date_Time__c',
                'Sample Approved' => 'Sample_Approved_Date_Time__c',
                'Negotiation' => 'Negotiation_Capture_Date_Time__c',
                'Closed Won' => 'Closed_Capture_Date_Time__c',
                'Closed Lost' => 'Closed_Capture_Date_Time__c'
			};
                
		for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap != null ? oldMap.get(opp.Id) : null;
            if (statusFieldMap.containsKey(opp.StageName) && 
                (oldOpp == null || opp.StageName != oldOpp.StageName)) {
                    String fieldName = statusFieldMap.get(opp.StageName);
                    Opp.put(fieldName, DateTime.now());
                }
        }
    } 
    
}