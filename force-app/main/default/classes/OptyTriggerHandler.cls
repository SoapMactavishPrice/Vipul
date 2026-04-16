public class OptyTriggerHandler {
    public static void convertHandler(List<Lead> newRecords, Map<Id, Lead> oldLeadMap) {
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Id> leadIdToOppId = new Map<Id, Id>();
        Map<Id, Id> leadToAccountId = new Map<Id, Id>();

        for (Lead lead : newRecords) {
            Lead oldLead = oldLeadMap.get(lead.Id);
            if (lead.IsConverted && !oldLead.IsConverted) {
                if (String.isNotBlank(lead.ConvertedOpportunityId)) {
                    leadIdToOppId.put(lead.Id, lead.ConvertedOpportunityId);
                }
                if (lead.ConvertedAccountId != null) {
                    leadToAccountId.put(lead.Id, lead.ConvertedAccountId);
                }
            }
        }

        if (leadIdToOppId.isEmpty()) return;

        // Fetch product interested
        List<Product_Interested__c> piList = [
            SELECT Id, Vipul_Product_Name__c, Lead__c, Vipul_Product_Name__r.Name,
                   Quantity__c, Price__c, Product_Family__c, Add_in_Opportunity__c,
                   Product_Code__c, Name, Quality__c, Packaging__c, New_Product__c,
                   New_Product_Name__c, New_Product_CI_No__c
            FROM Product_Interested__c 
            WHERE Lead__c IN :leadToAccountId.keySet()
        ];

        List<Product_Interested__c> piToUpdate = new List<Product_Interested__c>();
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        List<Product2> productsToInsert = new List<Product2>();
        Set<Id> existingProductIds = new Set<Id>();
        Map<String, Product_Interested__c> newProductNameToPI = new Map<String, Product_Interested__c>();

        for (Product_Interested__c pi : piList) {
            if (leadToAccountId.containsKey(pi.Lead__c)) {
                pi.Account__c = leadToAccountId.get(pi.Lead__c);
                piToUpdate.add(pi);
            }

            if (pi.New_Product__c && String.isNotBlank(pi.New_Product_Name__c)) {
                if (!newProductNameToPI.containsKey(pi.New_Product_Name__c)) {
                    newProductNameToPI.put(pi.New_Product_Name__c, pi);
                }
            } else if (pi.Vipul_Product_Name__c != null) {
                existingProductIds.add(pi.Vipul_Product_Name__c);
            }
        }

        // Create new products
        for (Product_Interested__c pi : newProductNameToPI.values()) {
            productsToInsert.add(new Product2(
                Name = pi.New_Product_Name__c,
                CI_no__c = pi.New_Product_CI_No__c,
                IsActive = true
            ));
        }

        Map<String, Id> newProductNameToId = new Map<String, Id>();
        if (!productsToInsert.isEmpty()) {
            insert productsToInsert;
            for (Product2 p : productsToInsert) {
                newProductNameToId.put(p.Name, p.Id);
            }
        }

        existingProductIds.addAll(newProductNameToId.values());

        // Fetch Standard Pricebook
        Id standardPBId = [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book' LIMIT 1].Id;

        // Map of lead currency
        Map<Id, String> leadCurrencyMap = new Map<Id, String>();
        for (Lead l : [
            SELECT Id, CurrencyIsoCode FROM Lead WHERE Id IN :leadIdToOppId.keySet()
        ]) {
            leadCurrencyMap.put(l.Id, l.CurrencyIsoCode);
        }

        // Fetch Opportunities
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, CurrencyIsoCode
            FROM Opportunity
            WHERE Id IN :leadIdToOppId.values()
        ]);

        // Fetch existing PBEs
        List<PricebookEntry> pbeList = [
            SELECT Id, Product2Id, CurrencyIsoCode, UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2Id = :standardPBId
            AND IsActive = true
            AND Product2Id IN :existingProductIds
        ];

        Map<String, PricebookEntry> productCurrencyToPbe = new Map<String, PricebookEntry>();
        for (PricebookEntry pbe : pbeList) {
            String key = pbe.Product2Id + '_' + pbe.CurrencyIsoCode;
            productCurrencyToPbe.put(key, pbe);
        }

        // Create missing PBEs
        List<PricebookEntry> pbesToInsert = new List<PricebookEntry>();
        for (Id productId : newProductNameToId.values()) {
            for (Id leadId : leadIdToOppId.keySet()) {
                String currencyCode = leadCurrencyMap.get(leadId);
                if (currencyCode == null) continue;

                String key = productId + '_' + currencyCode;
                if (!productCurrencyToPbe.containsKey(key)) {
                    PricebookEntry pbe = new PricebookEntry(
                        Product2Id = productId,
                        Pricebook2Id = standardPBId,
                        UnitPrice = 0,
                        IsActive = true,
                        CurrencyIsoCode = currencyCode
                    );
                    pbesToInsert.add(pbe);
                    productCurrencyToPbe.put(key, pbe); // optimistic mapping
                }
            }
        }

        if (!pbesToInsert.isEmpty()) {
            insert pbesToInsert;
        }

        // Now build OpportunityLineItems
        for (Product_Interested__c pi : piList) {
            if (!pi.Add_in_Opportunity__c) continue;

            Id oppId = leadIdToOppId.get(pi.Lead__c);
            Opportunity opp = oppMap.get(oppId);
            if (opp == null) continue;

            Id productId;
            if (pi.New_Product__c && String.isNotBlank(pi.New_Product_Name__c)) {
                productId = newProductNameToId.get(pi.New_Product_Name__c);
            } else {
                productId = pi.Vipul_Product_Name__c;
            }

            String pbeKey = productId + '_' + opp.CurrencyIsoCode;
            PricebookEntry pbe = productCurrencyToPbe.get(pbeKey);
            if (pbe == null) continue;
            
            Decimal quantity = (pi.Quantity__c == null || pi.Quantity__c == 0) ? 1 : pi.Quantity__c;
            
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opp.Id,
                PricebookEntryId = pbe.Id,
                Quantity = quantity,
                UnitPrice = pi.Price__c != null ? pi.Price__c : 0,
                Quality__c = pi.Quality__c,
                Packaging__c = pi.Packaging__c,
                Request_Purchase_Price__c = (pbe.UnitPrice == 0)
            );
            oliList.add(oli);
        }
        
        if (!piToUpdate.isEmpty()) update piToUpdate;
        if (!oliList.isEmpty()) insert oliList;
    }
}