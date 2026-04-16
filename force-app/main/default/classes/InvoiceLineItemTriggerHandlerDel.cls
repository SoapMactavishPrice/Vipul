public class InvoiceLineItemTriggerHandlerDel {
    
    // Cache for currency conversion rates
    private static Map<String, Decimal> currencyRateCache = new Map<String, Decimal>();
    
    public static void updateQuantityOnTargetDelete(List<Invoice_Line_Item__c> invoiceLineItemList) {
        System.debug('====> Entered updateQuantityOnTargetDelete method');

        if (invoiceLineItemList == null || invoiceLineItemList.isEmpty()) {
            return;
        }

        Set<Id> invoiceLineItemIds = new Set<Id>();
        Set<Id> orderOwnerIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> productIds = new Set<Id>();
        Set<String> currencies = new Set<String>();
        Date earliestDate = Date.today().addYears(100);
        Date latestDate = Date.today().addYears(-100);

        // Collect IDs from trigger records (not relationship fields)
        for (Invoice_Line_Item__c inv : invoiceLineItemList) {
            if (inv != null) {
                invoiceLineItemIds.add(inv.Id);
                if (inv.ItemName__c != null) productIds.add(inv.ItemName__c);
                if (inv.CurrencyIsoCode != null) currencies.add(inv.CurrencyIsoCode);
            }
        }

        if (invoiceLineItemIds.isEmpty()) {
            return;
        }

        // Query full line items with related data (including deleted)
        List<Invoice_Line_Item__c> fullLineItems = [
            SELECT Id, Quantity__c, Line_Total_Before_Tax__c, ItemName__c, Account__c,
                   Invoice__r.Account__c, Invoice__r.Order__r.OwnerId, Invoice__r.ARI_Date__c,
                   CurrencyIsoCode
            FROM Invoice_Line_Item__c 
            WHERE Id IN :invoiceLineItemIds
            ALL ROWS
        ];

        if (fullLineItems.isEmpty()) {
            return;
        }

        // Process line items and collect data
        for (Invoice_Line_Item__c inl : fullLineItems) {
            if (inl.Invoice__r != null && inl.Invoice__r.Order__r != null) {
                orderOwnerIds.add(inl.Invoice__r.Order__r.OwnerId);
                
                // FIXED: Collect Account from Invoice, not line item
                if (inl.Invoice__r.Account__c != null) {
                    accountIds.add(inl.Invoice__r.Account__c);
                }
                
                // FIXED: Track date range (min/max)
                if (inl.Invoice__r.ARI_Date__c < earliestDate) {
                    earliestDate = inl.Invoice__r.ARI_Date__c;
                }
                if (inl.Invoice__r.ARI_Date__c > latestDate) {
                    latestDate = inl.Invoice__r.ARI_Date__c;
                }
                
                // Collect currencies
                if (inl.CurrencyIsoCode != null) {
                    currencies.add(inl.CurrencyIsoCode);
                }
            }
        }

        if (orderOwnerIds.isEmpty()) {
            return;
        }

        // FIXED: Load currency rates
        loadCurrencyRates(currencies);

        // Fetch Employee Wise Account Target Data
        Map<Id, Employee_Wise_Account_Target_Line_Item__c> empAccTargetMap = new Map<Id, Employee_Wise_Account_Target_Line_Item__c>();
        for (Employee_Wise_Account_Target_Line_Item__c empAcc : [
            SELECT Id, Employee_Wise_Account_Target__r.Employee__c, 
                   Employee_Wise_Account_Target__r.Account__c, 
                   Actual_Quantity__c, Actual_Amount__c,
                   Start_Date__c, End_Date__c, CurrencyIsoCode
            FROM Employee_Wise_Account_Target_Line_Item__c 
            WHERE Employee_Wise_Account_Target__r.Employee__c IN :orderOwnerIds
            AND Employee_Wise_Account_Target__r.Account__c IN :accountIds
            AND Start_Date__c <= :latestDate 
            AND End_Date__c >= :earliestDate
        ]) {
            empAccTargetMap.put(empAcc.Id, empAcc);
            if (empAcc.CurrencyIsoCode != null) currencies.add(empAcc.CurrencyIsoCode);
        }
        
        // FIXED: Update Employee Wise Account Targets with proper account and currency conversion
        for (Invoice_Line_Item__c inl : fullLineItems) {
            Id ownerId = inl.Invoice__r.Order__r.OwnerId;
            Id accountId = inl.Invoice__r.Account__c;  // Using Invoice Account
            Decimal quantity = inl.Quantity__c != null ? inl.Quantity__c : 0;
            Decimal amount = inl.Line_Total_Before_Tax__c != null ? inl.Line_Total_Before_Tax__c : 0;
            String invoiceCurrency = inl.CurrencyIsoCode;
            Date lineItemDate = inl.Invoice__r.ARI_Date__c;
            
            for (Employee_Wise_Account_Target_Line_Item__c target : empAccTargetMap.values()) {
                if (target.Employee_Wise_Account_Target__r.Employee__c == ownerId &&
                    target.Employee_Wise_Account_Target__r.Account__c == accountId &&
                    lineItemDate >= target.Start_Date__c && 
                    lineItemDate <= target.End_Date__c) {
                    
                    Decimal convertedAmount = convertCurrencyOptimized(amount, invoiceCurrency, target.CurrencyIsoCode);
                    target.Actual_Quantity__c = (target.Actual_Quantity__c != null ? target.Actual_Quantity__c : 0) - quantity;
                    target.Actual_Amount__c = (target.Actual_Amount__c != null ? target.Actual_Amount__c : 0) - convertedAmount;
                }
            }
        }
        
        // Update Employee Wise Account Targets
        try {
            if (!empAccTargetMap.isEmpty()) {
                update empAccTargetMap.values();
            }
        } catch (Exception ex) {
            System.debug('====> Error updating Employee Wise Account Targets: ' + ex.getMessage());
        }

        // Fetch Employee Wise Target Data
        Map<Id, Employee_Wise_Target_Line_Item__c> empTargetMap = new Map<Id, Employee_Wise_Target_Line_Item__c>();
        for (Employee_Wise_Target_Line_Item__c emp : [
            SELECT Id, Employee_Wise_Target__r.Employee__c, 
                   Actual_Quantity__c, Actual_Amount__c,
                   Start_Date__c, End_Date__c, CurrencyIsoCode
            FROM Employee_Wise_Target_Line_Item__c 
            WHERE Employee_Wise_Target__r.Employee__c IN :orderOwnerIds 
            AND Start_Date__c <= :latestDate 
            AND End_Date__c >= :earliestDate
        ]) {
            empTargetMap.put(emp.Id, emp);
            if (emp.CurrencyIsoCode != null) currencies.add(emp.CurrencyIsoCode);
        }

        // Update Employee Wise Targets
        for (Invoice_Line_Item__c inl : fullLineItems) {
            Id ownerId = inl.Invoice__r.Order__r.OwnerId;
            Decimal amount = inl.Line_Total_Before_Tax__c != null ? inl.Line_Total_Before_Tax__c : 0;
            String invoiceCurrency = inl.CurrencyIsoCode;
            Date lineItemDate = inl.Invoice__r.ARI_Date__c;
            
            for (Employee_Wise_Target_Line_Item__c target : empTargetMap.values()) {
                if (target.Employee_Wise_Target__r.Employee__c == ownerId &&
                    lineItemDate >= target.Start_Date__c && 
                    lineItemDate <= target.End_Date__c) {
                    
                    Decimal convertedAmount = convertCurrencyOptimized(amount, invoiceCurrency, target.CurrencyIsoCode);
                    target.Actual_Amount__c = (target.Actual_Amount__c != null ? target.Actual_Amount__c : 0) - convertedAmount;
                    // Note: Employee Wise Target doesn't track quantity
                }
            }
        }

        // Update Employee Wise Targets
        try {
            if (!empTargetMap.isEmpty()) {
                update empTargetMap.values();
            }
        } catch (Exception ex) {
            System.debug('====> Error updating Employee Wise Targets: ' + ex.getMessage());
        }

        // Fetch Account Wise Product Target Data
        Map<Id, Account_Wise_Product_Target_Line_Item__c> accProdTargetMap = new Map<Id, Account_Wise_Product_Target_Line_Item__c>();
        for (Account_Wise_Product_Target_Line_Item__c accProd : [
            SELECT Id, Account_Wise_Product_Target__r.Account__c,
                   Account_Wise_Product_Target__r.Product__c,
                   Actual_Quantity__c, Actual_Amount__c,
                   Start_Date__c, End_Date__c, CurrencyIsoCode
            FROM Account_Wise_Product_Target_Line_Item__c
            WHERE Account_Wise_Product_Target__r.Account__c IN :accountIds
            AND Account_Wise_Product_Target__r.Product__c IN :productIds
            AND Start_Date__c <= :latestDate 
            AND End_Date__c >= :earliestDate
        ]) {
            accProdTargetMap.put(accProd.Id, accProd);
            if (accProd.CurrencyIsoCode != null) currencies.add(accProd.CurrencyIsoCode);
        }

        // Update Account Wise Product Targets
        for (Invoice_Line_Item__c inl : fullLineItems) {
            Id accountId = inl.Invoice__r.Account__c;  // Using Invoice Account
            Id productId = inl.ItemName__c;
            Decimal quantity = inl.Quantity__c != null ? inl.Quantity__c : 0;
            Decimal amount = inl.Line_Total_Before_Tax__c != null ? inl.Line_Total_Before_Tax__c : 0;
            String invoiceCurrency = inl.CurrencyIsoCode;
            Date lineItemDate = inl.Invoice__r.ARI_Date__c;
            
            for (Account_Wise_Product_Target_Line_Item__c target : accProdTargetMap.values()) {
                if (target.Account_Wise_Product_Target__r.Account__c == accountId &&
                    target.Account_Wise_Product_Target__r.Product__c == productId &&
                    lineItemDate >= target.Start_Date__c && 
                    lineItemDate <= target.End_Date__c) {
                    
                    Decimal convertedAmount = convertCurrencyOptimized(amount, invoiceCurrency, target.CurrencyIsoCode);
                    target.Actual_Quantity__c = (target.Actual_Quantity__c != null ? target.Actual_Quantity__c : 0) - quantity;
                    target.Actual_Amount__c = (target.Actual_Amount__c != null ? target.Actual_Amount__c : 0) - convertedAmount;
                }
            }
        }

        // Update Account Wise Product Targets
        try {
            if (!accProdTargetMap.isEmpty()) {
                update accProdTargetMap.values();
            }
        } catch (Exception ex) {
            System.debug('====> Error updating Account Wise Product Targets: ' + ex.getMessage());
        }

        // Fetch Employee Wise Product Target Data
        Map<Id, Employee_Wise_Product_Target_Line_Item__c> empProdTargetMap = new Map<Id, Employee_Wise_Product_Target_Line_Item__c>();
        for (Employee_Wise_Product_Target_Line_Item__c empProd : [
            SELECT Id, Employee_Wise_Product_Target__r.Employee__c, 
                   Employee_Wise_Product_Target__r.Product__c, 
                   Actual_Quantity__c, Actual_Amount__c,
                   Start_Date__c, End_Date__c, CurrencyIsoCode
            FROM Employee_Wise_Product_Target_Line_Item__c
            WHERE Employee_Wise_Product_Target__r.Employee__c IN :orderOwnerIds
            AND Employee_Wise_Product_Target__r.Product__c IN :productIds
            AND Start_Date__c <= :latestDate 
            AND End_Date__c >= :earliestDate
        ]) {
            empProdTargetMap.put(empProd.Id, empProd);
            if (empProd.CurrencyIsoCode != null) currencies.add(empProd.CurrencyIsoCode);
        }

        // FIXED: Update Employee Wise Product Targets (check both employee AND product)
        for (Invoice_Line_Item__c inl : fullLineItems) {
            Id ownerId = inl.Invoice__r.Order__r.OwnerId;
            Id productId = inl.ItemName__c;
            Decimal quantity = inl.Quantity__c != null ? inl.Quantity__c : 0;
            Decimal amount = inl.Line_Total_Before_Tax__c != null ? inl.Line_Total_Before_Tax__c : 0;
            String invoiceCurrency = inl.CurrencyIsoCode;
            Date lineItemDate = inl.Invoice__r.ARI_Date__c;
            
            for (Employee_Wise_Product_Target_Line_Item__c target : empProdTargetMap.values()) {
                if (target.Employee_Wise_Product_Target__r.Employee__c == ownerId &&
                    target.Employee_Wise_Product_Target__r.Product__c == productId &&
                    lineItemDate >= target.Start_Date__c && 
                    lineItemDate <= target.End_Date__c) {
                    
                    Decimal convertedAmount = convertCurrencyOptimized(amount, invoiceCurrency, target.CurrencyIsoCode);
                    target.Actual_Quantity__c = (target.Actual_Quantity__c != null ? target.Actual_Quantity__c : 0) - quantity;
                    target.Actual_Amount__c = (target.Actual_Amount__c != null ? target.Actual_Amount__c : 0) - convertedAmount;
                }
            }
        }

        // Update Employee Wise Product Targets
        try {
            if (!empProdTargetMap.isEmpty()) {
                update empProdTargetMap.values();
            }
        } catch (Exception ex) {
            System.debug('====> Error updating Employee Wise Product Targets: ' + ex.getMessage());
        }
        
        System.debug('====> Exiting updateQuantityOnTargetDelete method');
    }
    
    /**
     * Load currency conversion rates for all currencies needed
     */
    private static void loadCurrencyRates(Set<String> currencies) {
        if (currencies == null || currencies.isEmpty()) {
            return;
        }
        
        currencyRateCache.clear();
        
        for (CurrencyType ct : [SELECT ConversionRate, IsoCode 
                               FROM CurrencyType 
                               WHERE IsoCode IN :currencies]) {
            currencyRateCache.put(ct.IsoCode, ct.ConversionRate);
        }
        
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
            
            if (fromRate == null) fromRate = 1.0;
            if (toRate == null) toRate = 1.0;
            
            Decimal amountInCorporate = amount / fromRate;
            return amountInCorporate * toRate;
            
        } catch (Exception e) {
            System.debug('Currency conversion error: ' + e.getMessage());
            return amount;
        }
    }
}