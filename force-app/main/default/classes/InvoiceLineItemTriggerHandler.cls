public class InvoiceLineItemTriggerHandler {
    
    // Cache for currency conversion rates
    private static Map<String, Decimal> currencyRateCache = new Map<String, Decimal>();
    
    public static void updateQuantityOnTarget(List<Invoice_Line_Item__c> invoiceLineItems) {
        if (invoiceLineItems == null || invoiceLineItems.isEmpty()) {
            return;
        }

        Set<Id> invoiceLineItemIds = new Set<Id>();
        Set<Id> orderOwnerIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        Set<String> currencies = new Set<String>();
        Date earliestDate = Date.today().addYears(100);
        Date latestDate = Date.today().addYears(-100);

        // Collect initial data
    /*    for (Invoice_Line_Item__c ili : invoiceLineItems) {
            if (ili != null) {
                invoiceLineItemIds.add(ili.Id);
              //  if (ili.Account__c != null) accountIds.add(ili.Account__c);
                if (ili.Invoice__r.Account__c != null) {
                    accountIds.add(ili.Invoice__r.Account__c);
                }
                if (ili.ItemName__c != null) productIds.add(ili.ItemName__c);
                if (ili.CurrencyIsoCode != null) currencies.add(ili.CurrencyIsoCode);
            }
        }	*/
        
        for (Invoice_Line_Item__c ili : invoiceLineItems) {
            if (ili != null) {
                invoiceLineItemIds.add(ili.Id);
                
                if (ili.ItemName__c != null) productIds.add(ili.ItemName__c);
                if (ili.CurrencyIsoCode != null) currencies.add(ili.CurrencyIsoCode);
            }
        }

        if (invoiceLineItemIds.isEmpty()) {
            return;
        }

        // Query full line items with related data
        List<Invoice_Line_Item__c> fullLineItems = [
            SELECT Id, Quantity__c, Line_Total_Before_Tax__c, ItemName__c, Account__c,
                   Invoice__r.Account__c,Invoice__r.Order__r.OwnerId, Invoice__r.ARI_Date__c,
                   CurrencyIsoCode
            FROM Invoice_Line_Item__c 
            WHERE Id IN :invoiceLineItemIds
            AND Invoice__r.Order__r.OwnerId != null
            AND Invoice__r.ARI_Date__c != null
        ];

        if (fullLineItems.isEmpty()) {
            return;
        }

        // Process line items and collect more data
    /*    for (Invoice_Line_Item__c ili : fullLineItems) {
            orderOwnerIds.add(ili.Invoice__r.Order__r.OwnerId);
            if (ili.Invoice__r.ARI_Date__c < earliestDate) {
                earliestDate = ili.Invoice__r.ARI_Date__c;
            }
            if (ili.Invoice__r.ARI_Date__c > latestDate) {
                latestDate = ili.Invoice__r.ARI_Date__c;
            }
            if (ili.CurrencyIsoCode != null) {
                currencies.add(ili.CurrencyIsoCode);
            }
        }	*/
        
        for (Invoice_Line_Item__c ili : fullLineItems) {
            
            orderOwnerIds.add(ili.Invoice__r.Order__r.OwnerId);
            
            if (ili.Invoice__r.Account__c != null) {
                accountIds.add(ili.Invoice__r.Account__c);
            }
            
            if (ili.Invoice__r.ARI_Date__c < earliestDate) {
                earliestDate = ili.Invoice__r.ARI_Date__c;
            }
            
            if (ili.Invoice__r.ARI_Date__c > latestDate) {
                latestDate = ili.Invoice__r.ARI_Date__c;
            }
            
            if (ili.CurrencyIsoCode != null) {
                currencies.add(ili.CurrencyIsoCode);
            }
        }

        // Initialize target maps
        Map<Id, Employee_Wise_Target_Line_Item__c> empTargetMap = new Map<Id, Employee_Wise_Target_Line_Item__c>();
        Map<Id, Employee_Wise_Account_Target_Line_Item__c> empAccTargetMap = new Map<Id, Employee_Wise_Account_Target_Line_Item__c>();
        Map<Id, Employee_Wise_Product_Target_Line_Item__c> empProdTargetMap = new Map<Id, Employee_Wise_Product_Target_Line_Item__c>();
        Map<Id, Account_Wise_Product_Target_Line_Item__c> accProdTargetMap = new Map<Id, Account_Wise_Product_Target_Line_Item__c>();

        try {
            // Load all target line items
            for (Employee_Wise_Target_Line_Item__c target : [
                SELECT Id, Employee_Wise_Target__r.Employee__c, 
                       Actual_Quantity__c, Actual_Amount__c,
                       Start_Date__c, End_Date__c,
                       CurrencyIsoCode
                FROM Employee_Wise_Target_Line_Item__c 
                WHERE Employee_Wise_Target__r.Employee__c IN :orderOwnerIds
                AND Start_Date__c <= :latestDate
                AND End_Date__c >= :earliestDate
                AND Employee_Wise_Target__r.Employee__c != null
            ]) {
                empTargetMap.put(target.Id, target);
                if (target.CurrencyIsoCode != null) currencies.add(target.CurrencyIsoCode);
            }

            for (Employee_Wise_Account_Target_Line_Item__c target : [
                SELECT Id, Employee_Wise_Account_Target__r.Employee__c, 
                       Employee_Wise_Account_Target__r.Account__c,
                       Actual_Quantity__c, Actual_Amount__c,
                       Start_Date__c, End_Date__c,
                       CurrencyIsoCode
                FROM Employee_Wise_Account_Target_Line_Item__c 
                WHERE Employee_Wise_Account_Target__r.Employee__c IN :orderOwnerIds
                AND Employee_Wise_Account_Target__r.Account__c IN :accountIds
                AND Start_Date__c <= :latestDate
                AND End_Date__c >= :earliestDate
                AND Employee_Wise_Account_Target__r.Employee__c != null
                AND Employee_Wise_Account_Target__r.Account__c != null
            ]) {
                empAccTargetMap.put(target.Id, target);
                if (target.CurrencyIsoCode != null) currencies.add(target.CurrencyIsoCode);
            }

            for (Employee_Wise_Product_Target_Line_Item__c target : [
                SELECT Id, Employee_Wise_Product_Target__r.Employee__c,
                       Employee_Wise_Product_Target__r.Product__c,
                       Actual_Quantity__c, Actual_Amount__c,
                       Start_Date__c, End_Date__c,
                       CurrencyIsoCode
                FROM Employee_Wise_Product_Target_Line_Item__c
                WHERE Employee_Wise_Product_Target__r.Employee__c IN :orderOwnerIds
                AND Employee_Wise_Product_Target__r.Product__c IN :productIds
                AND Start_Date__c <= :latestDate
                AND End_Date__c >= :earliestDate
                AND Employee_Wise_Product_Target__r.Employee__c != null
                AND Employee_Wise_Product_Target__r.Product__c != null
            ]) {
                empProdTargetMap.put(target.Id, target);
                if (target.CurrencyIsoCode != null) currencies.add(target.CurrencyIsoCode);
            }

            for (Account_Wise_Product_Target_Line_Item__c target : [
                SELECT Id, Account_Wise_Product_Target__r.Account__c,
                       Account_Wise_Product_Target__r.Product__c,
                       Actual_Quantity__c, Actual_Amount__c,
                       Start_Date__c, End_Date__c,
                       CurrencyIsoCode
                FROM Account_Wise_Product_Target_Line_Item__c 
                WHERE Account_Wise_Product_Target__r.Account__c IN :accountIds
                AND Account_Wise_Product_Target__r.Product__c IN :productIds
                AND Start_Date__c <= :latestDate
                AND End_Date__c >= :earliestDate
                AND Account_Wise_Product_Target__r.Account__c != null
                AND Account_Wise_Product_Target__r.Product__c != null
            ]) {
                accProdTargetMap.put(target.Id, target);
                if (target.CurrencyIsoCode != null) currencies.add(target.CurrencyIsoCode);
            }

            // Load all currency rates in a single query
            loadCurrencyRates(currencies);

            // Process each line item and update targets
            for (Invoice_Line_Item__c ili : fullLineItems) {
                Date lineItemDate = ili.Invoice__r.ARI_Date__c;
                Id ownerId = ili.Invoice__r.Order__r.OwnerId;
            //    Id accountId = ili.Account__c;
            	Id accountId = ili.Invoice__r.Account__c;
                Id productId = ili.ItemName__c;
                Decimal quantity = ili.Quantity__c != null ? ili.Quantity__c : 0;
                Decimal amount = ili.Line_Total_Before_Tax__c != null ? ili.Line_Total_Before_Tax__c : 0;
                String invoiceCurrency = ili.CurrencyIsoCode;

                // Update Employee Wise Targets
                for (Employee_Wise_Target_Line_Item__c target : empTargetMap.values()) {
                    if (target.Employee_Wise_Target__r != null && 
                        target.Employee_Wise_Target__r.Employee__c == ownerId &&
                        lineItemDate >= target.Start_Date__c && 
                        lineItemDate <= target.End_Date__c) {
                        Decimal convertedAmount = convertCurrencyOptimized(amount, invoiceCurrency, target.CurrencyIsoCode);
                        target.Actual_Amount__c = (target.Actual_Amount__c != null ? target.Actual_Amount__c : 0) + convertedAmount;
                    }
                }

                // Update Employee Wise Account Targets
                for (Employee_Wise_Account_Target_Line_Item__c target : empAccTargetMap.values()) {
                    if (target.Employee_Wise_Account_Target__r != null &&
                        target.Employee_Wise_Account_Target__r.Employee__c == ownerId &&
                        target.Employee_Wise_Account_Target__r.Account__c == accountId &&
                        lineItemDate >= target.Start_Date__c && 
                        lineItemDate <= target.End_Date__c) {
                        target.Actual_Quantity__c = (target.Actual_Quantity__c != null ? target.Actual_Quantity__c : 0) + quantity;
                        Decimal convertedAmount = convertCurrencyOptimized(amount, invoiceCurrency, target.CurrencyIsoCode);
                        target.Actual_Amount__c = (target.Actual_Amount__c != null ? target.Actual_Amount__c : 0) + convertedAmount;
                    }
                }

                // Update Employee Wise Product Targets
                for (Employee_Wise_Product_Target_Line_Item__c target : empProdTargetMap.values()) {
                    if (target.Employee_Wise_Product_Target__r != null &&
                        target.Employee_Wise_Product_Target__r.Employee__c == ownerId &&
                        target.Employee_Wise_Product_Target__r.Product__c == productId &&
                        lineItemDate >= target.Start_Date__c && 
                        lineItemDate <= target.End_Date__c) {
                        target.Actual_Quantity__c = (target.Actual_Quantity__c != null ? target.Actual_Quantity__c : 0) + quantity;
                        Decimal convertedAmount = convertCurrencyOptimized(amount, invoiceCurrency, target.CurrencyIsoCode);
                        target.Actual_Amount__c = (target.Actual_Amount__c != null ? target.Actual_Amount__c : 0) + convertedAmount;
                    }
                }

                // Update Account Wise Product Targets
                for (Account_Wise_Product_Target_Line_Item__c target : accProdTargetMap.values()) {
                    if (target.Account_Wise_Product_Target__r != null &&
                        target.Account_Wise_Product_Target__r.Account__c == accountId &&
                        target.Account_Wise_Product_Target__r.Product__c == productId &&
                        lineItemDate >= target.Start_Date__c && 
                        lineItemDate <= target.End_Date__c) {
                        target.Actual_Quantity__c = (target.Actual_Quantity__c != null ? target.Actual_Quantity__c : 0) + quantity;
                        Decimal convertedAmount = convertCurrencyOptimized(amount, invoiceCurrency, target.CurrencyIsoCode);
                        target.Actual_Amount__c = (target.Actual_Amount__c != null ? target.Actual_Amount__c : 0) + convertedAmount;
                    }
                }
            }

            // Update all target records
            List<Database.SaveResult> results = new List<Database.SaveResult>();
            
            if (!empTargetMap.isEmpty()) {
                results.addAll(Database.update(empTargetMap.values(), false));
            }
            if (!empAccTargetMap.isEmpty()) {
                results.addAll(Database.update(empAccTargetMap.values(), false));
            }
            if (!empProdTargetMap.isEmpty()) {
                results.addAll(Database.update(empProdTargetMap.values(), false));
            }
            if (!accProdTargetMap.isEmpty()) {
                results.addAll(Database.update(accProdTargetMap.values(), false));
            }

            // Check for update errors
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('Error updating target record: ' + err.getMessage());
                    }
                }
            }

        } catch (Exception e) {
            // Log the exception properly
            System.debug('Error in updateQuantityOnTarget: ' + e.getMessage() + 
                        '\nStack Trace: ' + e.getStackTraceString());
            // Re-throw or handle as needed for your use case
            // throw new AuraHandledException('Failed to update target quantities: ' + e.getMessage());
        }
    }

    /**
     * Load currency conversion rates for all currencies needed
     */
    private static void loadCurrencyRates(Set<String> currencies) {
        if (currencies == null || currencies.isEmpty()) {
            return;
        }
        
        // Clear cache for fresh data
        currencyRateCache.clear();
        
        // Query all needed currencies at once
        for (CurrencyType ct : [SELECT ConversionRate, IsoCode 
                               FROM CurrencyType 
                               WHERE IsoCode IN :currencies]) {
            currencyRateCache.put(ct.IsoCode, ct.ConversionRate);
        }
        
        // Always include USD with rate 1.0 as fallback
        if (!currencyRateCache.containsKey('USD')) {
            currencyRateCache.put('USD', 1.0);
        }
    }

    /**
     * Optimized currency conversion using cached rates
     */
    private static Decimal convertCurrencyOptimized(Decimal amount, String fromCurrency, String toCurrency) {
        if (amount == null || amount == 0 || fromCurrency == toCurrency || fromCurrency == null || toCurrency == null) {
            return amount;
        }
        
        try {
            Decimal fromRate = currencyRateCache.get(fromCurrency);
            Decimal toRate = currencyRateCache.get(toCurrency);
            
            // Use default rates if not in cache
            if (fromRate == null) fromRate = 1.0;
            if (toRate == null) toRate = 1.0;
            
            Decimal amountInCorporate = amount / fromRate;
            return amountInCorporate * toRate;
            
        } catch (Exception e) {
            // Fallback: return original amount
            System.debug('Currency conversion error: ' + e.getMessage());
            return amount;
        }
    }

    /**
     * Original method kept for backward compatibility
     * Uses optimized conversion internally
     */
    private static Decimal convertCurrency(Decimal amount, String fromCurrency, String toCurrency) {
        if (amount == null || amount == 0 || fromCurrency == toCurrency || fromCurrency == null || toCurrency == null) {
            return amount;
        }
        
        try {
            // If cache is empty, load rates for these currencies
            if (currencyRateCache.isEmpty()) {
                Set<String> currencies = new Set<String>{fromCurrency, toCurrency};
                loadCurrencyRates(currencies);
            }
            
            return convertCurrencyOptimized(amount, fromCurrency, toCurrency);
            
        } catch (Exception e) {
            System.debug('Currency conversion error: ' + e.getMessage());
            return amount;
        }
    }
    
}