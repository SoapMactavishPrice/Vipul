public class QuoteTriggerHandler {
    
    public static void createOrder(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {
        List<Order> ordersToInsert = new List<Order>();
        Map<Id, Quote> quoteIdToQuoteMap = new Map<Id, Quote>();
        Map<Id, Proforma_Invoice__c> quoteToPIMap = new Map<Id, Proforma_Invoice__c>();

        // Step 1: Identify Quotes where SAP_SO_Number__c is newly populated
        for (Quote q : newQuotes) {
            Quote oldQ = oldQuoteMap.get(q.Id);
            if (q.SAP_SO_Number__c != null &&
                oldQ.SAP_SO_Number__c == null &&
                (q.Order_Created__c == null || q.Order_Created__c == false)) {
                quoteIdToQuoteMap.put(q.Id, q);
            }
        }

        if (quoteIdToQuoteMap.isEmpty()) return;

        // Step 2: Fetch related QuoteLineItems
        List<QuoteLineItem> qlis = [
            SELECT Id, QuoteId, Product2Id, Quantity, UnitPrice, PricebookEntryId,
                   Quality__c, Packing__c, Packing_Type__c, Purchase_Price_in_INR__c,
                   Converter__c, Margin_Type__c, Margin_Value__c, Margin_Percent__c,
                   Commission_Type__c, Commission_Value__c, Commission_Percent__c,
                   Freight_Value__c, Product_Family__c, Rejected_Purchase_Price__c,
                   Reject_Reason__c, Purchase_Price_Status__c, Request_Purchase_Price__c
            FROM QuoteLineItem
            WHERE QuoteId IN :quoteIdToQuoteMap.keySet()
        ];

        // Step 3: Group QuoteLineItems by QuoteId
        Map<Id, List<QuoteLineItem>> quoteToQLIMap = new Map<Id, List<QuoteLineItem>>();
        for (QuoteLineItem qli : qlis) {
            if (!quoteToQLIMap.containsKey(qli.QuoteId)) {
                quoteToQLIMap.put(qli.QuoteId, new List<QuoteLineItem>());
            }
            quoteToQLIMap.get(qli.QuoteId).add(qli);
        }
        
        for (Proforma_Invoice__c pi : [
            SELECT Id, Quote__c,
            Contact_Info_for_Logistic_Purpose__c,
            Nomination_Agent__c,
            ECGC_Status__c,
            Commission_if_Any__c,
            SIGNED_COPY_OF_SALES_Order__c,
            Type_of_Pallet__c,
            Container_Type__c,
            Vol_Logo_on_Packing__c,
            Shipment_Type__c
            FROM Proforma_Invoice__c
            WHERE Quote__c IN :quoteIdToQuoteMap.keySet()
        ]) {
            // Assuming 1 PI per Quote (if multiple, last one wins — adjust if needed)
            quoteToPIMap.put(pi.Quote__c, pi);
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

        List<OrderItem> oliToInsert = new List<OrderItem>();
        List<Quote> quotesToUpdate = new List<Quote>();
        Set<Id> opportunityIds = new Set<Id>();

        // Step 4: Create Orders
        for (Quote q : quoteIdToQuoteMap.values()) {
            
            Id locationId;
            
            if (q.Quote_Type__c == 'International') {
                locationId = locationByName.get('Andheri HO');
            } else {
                locationId = locationByName.get('Ambernath Factory');
            }
            
            Proforma_Invoice__c pi = quoteToPIMap.get(q.Id);
            
            Order o = new Order(
                OpportunityId = q.OpportunityId,
                AccountId = q.AccountId,
                QuoteId = q.Id,
                CustomerCode__c = q.Customer_Code__c,
                Pricebook2Id = q.Pricebook2Id,
                Agent_Name__c = q.Transporter_Name__c,
                Order_Type__c = q.Quote_Type__c,
                Inco_Terms__c = q.Inco_Terms__c,
                CurrencyIsoCode = q.CurrencyIsoCode,
                Payment_Terms__c = q.Payment_Terms__c,
                PoDate = q.PO_Date__c,
                PoNumber = q.PO_PI_Number__c,
                Description = q.Description,
                Transport_Value__c = q.Transport_Value__c,
                Include_TCS_Value__c = q.Include_TCS_Value__c,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Consignee_Address1__c = q.Consignee_Address1__c,
                Delivery_Address1__c = q.Delivery_Address1__c,
                Oracle_Sales_Order_No__c = q.SAP_SO_Number__c,
                Location__c = locationId,
                
                Contact_Info_for_Logistic_Purpose__c = (pi != null) ? pi.Contact_Info_for_Logistic_Purpose__c : null,
                ECGC_Status__c = (pi != null) ? pi.ECGC_Status__c : null,
                Commission_if_Any__c = (pi != null) ? pi.Commission_if_Any__c : null,
                SIGNED_COPY_OF_SALES_Order__c = (pi != null) ? pi.SIGNED_COPY_OF_SALES_Order__c : null,
                Type_of_Pallet__c = (pi != null) ? pi.Type_of_Pallet__c : null,
                Container_size__c = (pi != null) ? pi.Container_Type__c : null,
                Vol_Logo_on_Packing__c = (pi != null) ? pi.Vol_Logo_on_Packing__c : null,
                Shipment__c = (pi != null) ? pi.Shipment_Type__c : null
            );
            ordersToInsert.add(o);

            if (q.OpportunityId != null) {
                opportunityIds.add(q.OpportunityId);
            }
        }

        insert ordersToInsert;

        // Step 5: Create OrderItems and prepare Quote updates
        Integer index = 0;
        for (Quote q : quoteIdToQuoteMap.values()) {
            Order createdOrder = ordersToInsert[index++];
            List<QuoteLineItem> qliList = quoteToQLIMap.get(q.Id);
            
            Id warehouseId;
            
            if (q.Quote_Type__c == 'International') {
                warehouseId = warehouseByName.get('HO_BH_FT');
            } else {
                warehouseId = warehouseByName.get('AMB_FG_M');
            }

            if (qliList != null) {
                for (QuoteLineItem qli : qliList) {
                    OrderItem oli = new OrderItem(
                        OrderId = createdOrder.Id,
                        Product2Id = qli.Product2Id,
                        Quantity = qli.Quantity,
                        UnitPrice = qli.UnitPrice,
                        PricebookEntryId = qli.PricebookEntryId,
                        Warehouse__c = warehouseId,
                        Quality__c = qli.Quality__c,
                        Packaging__c = qli.Packing__c,
                        Packing_Type__c = qli.Packing_Type__c,
                        Purchase_Price_in_INR__c = qli.Purchase_Price_in_INR__c,
                        Converter__c = qli.Converter__c,
                        Margin_Type__c = qli.Margin_Type__c,
                        Margin_Value__c = qli.Margin_Value__c,
                        Margin_Percent__c = qli.Margin_Percent__c,
                        Commission_Type__c = qli.Commission_Type__c,
                        Commission_Value__c = qli.Commission_Value__c,
                        Commission_Percent__c = qli.Commission_Percent__c,
                        Freight_Value__c = qli.Freight_Value__c,
                        Product_Family__c = qli.Product_Family__c,
                        Rejected_Purchase_Price__c = qli.Rejected_Purchase_Price__c,
                        Reject_Reason__c = qli.Reject_Reason__c,
                        Purchase_Price_Status__c = qli.Purchase_Price_Status__c
                    );
                    oliToInsert.add(oli);
                }
            }

            Quote quoteToUpdate = new Quote(
                Id = q.Id,
                Order_Created__c = true
            );
            quotesToUpdate.add(quoteToUpdate);
        }

        insert oliToInsert;
        update quotesToUpdate;

        // Step 6: Update Opportunity StageName to 'Closed Won'
        if (!opportunityIds.isEmpty()) {
            List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
            for (Opportunity opp : [SELECT Id, StageName FROM Opportunity WHERE Id IN :opportunityIds]) {
                opp.StageName = 'Closed Won';
                opportunitiesToUpdate.add(opp);
            }
            update opportunitiesToUpdate;
        }
    }
    
    public static void updateStatusChangeFields(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap){
        
    
        Map<String, String> statusFieldMap = new Map<String, String>{
            'Draft' => 'Draft_Capture_Date_Time__c',
                'In Review' => 'In_Review_Capture_Date_Time__c',
                'Rejected' => 'Rejected_Capture_Date_Time__c',
                'Accepted' => 'Accepted_Capture_Date_Time__c'
                };
                    
                    Set<Id> oppsToCloseLost = new Set<Id>();
        Set<Id> oppsToCloseWon  = new Set<Id>();
        
        for (Quote qt : newQuotes) {
            Quote oldQuote = oldQuoteMap != null ? oldQuoteMap.get(qt.Id) : null;
            
            if (statusFieldMap.containsKey(qt.Status) &&
                (oldQuote == null || qt.Status != oldQuote.Status)) {
                    
                    qt.put(statusFieldMap.get(qt.Status), DateTime.now());
                }
            
            if (qt.OpportunityId == null) continue;
            
            // 1. Rejected → Closed Lost (Highest Priority)
            if (qt.Status == 'Rejected' &&
                (oldQuote == null || oldQuote.Status != 'Rejected')) {
                    
                    oppsToCloseLost.add(qt.OpportunityId);
                }
            
            // 2. Order Created → Closed Won (Only if NOT Rejected)
            else if (qt.Order_Created__c == true &&
                     (oldQuote == null || oldQuote.Order_Created__c != true)) {
                         
                         oppsToCloseWon.add(qt.OpportunityId);
                     }
        }
        
        if (!oppsToCloseLost.isEmpty() || !oppsToCloseWon.isEmpty()) {
            
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            
            for (Opportunity opp : [
                SELECT Id, StageName
                FROM Opportunity
                WHERE Id IN :oppsToCloseLost
                OR Id IN :oppsToCloseWon
            ]) {
                
                if (oppsToCloseLost.contains(opp.Id)) {
                    opp.StageName = 'Closed Lost';
                }
                else if (oppsToCloseWon.contains(opp.Id)) {
                    opp.StageName = 'Closed Won';
                }
                
                oppsToUpdate.add(opp);
            }
            
            update oppsToUpdate;
        }
    }
    
    
    public static void syncSAPCodeToProforma(List<Quote> newList, Map<Id, Quote> oldMap) {
        
        Set<Id> quoteIdsToProcess = new Set<Id>();
        Map<Id, String> quoteSAPMap = new Map<Id, String>();
        
        for (Quote q : newList) {
            
           // Quote oldQ = oldMap.get(q.Id);
           
              Quote oldQ = (oldMap != null) ? oldMap.get(q.Id) : null;
            
            // Run only first time SAP_SO_Number__c is populated
            if (
                String.isNotBlank(q.SAP_SO_Number__c) &&
                String.isBlank(oldQ.SAP_SO_Number__c)
            ) {
                quoteIdsToProcess.add(q.Id);
                quoteSAPMap.put(q.Id, q.SAP_SO_Number__c);
            }
        }
        
        if (quoteIdsToProcess.isEmpty()) return;
        
        List<Proforma_Invoice__c> invoicesToUpdate = new List<Proforma_Invoice__c>();
        
        for (Proforma_Invoice__c inv : [
            SELECT Id, Quote__c, SO_No__c, SO_Date__c
            FROM Proforma_Invoice__c
            WHERE Quote__c IN :quoteIdsToProcess
        ]) {
            // Update only if blank
            if (String.isBlank(inv.SO_No__c) && inv.SO_Date__c == null) {
                inv.SO_No__c = quoteSAPMap.get(inv.Quote__c);
                inv.SO_Date__c = Date.today();
                invoicesToUpdate.add(inv);
            }
        }
        
        if (!invoicesToUpdate.isEmpty()) {
            update invoicesToUpdate;
        }
    }
}