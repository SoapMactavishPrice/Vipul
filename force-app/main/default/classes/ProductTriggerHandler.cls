public class ProductTriggerHandler {
    public static void preventDuplicateProducts(List<Product2> newProducts) {
        Set<String> nameSet = new Set<String>();
        Set<String> codeSet = new Set<String>();

        for (Product2 p : newProducts) {
            if (p.Name != null) {
                nameSet.add(p.Name.trim());
            }
            if (p.ProductCode != null) {
                codeSet.add(p.ProductCode.trim());
            }
        }

        // Query existing products with matching Name or ProductCode
        List<Product2> existingProductList = [
            SELECT Id, Name, ProductCode
            FROM Product2
            WHERE Name IN :nameSet OR ProductCode IN :codeSet
        ];

        Set<String> existingNames = new Set<String>();
        Set<String> existingCodes = new Set<String>();

        for (Product2 p : existingProductList) {
            if (p.Name != null) {
                existingNames.add(p.Name.trim().toLowerCase());
            }
            if (p.ProductCode != null) {
                existingCodes.add(p.ProductCode.trim().toLowerCase());
            }
        }

        for (Product2 p : newProducts) {
            String nameKey = p.Name != null ? p.Name.trim().toLowerCase() : null;
            String codeKey = p.ProductCode != null ? p.ProductCode.trim().toLowerCase() : null;

            if (nameKey != null && existingNames.contains(nameKey)) {
                p.addError('A product with the same Name already exists.');
            } else if (codeKey != null && existingCodes.contains(codeKey)) {
                p.addError('A product with the same Product Code already exists.');
            }
        }
    }
    
    public static void createPricebookEntries(
        List<Product2> newProducts,
        Map<Id, Product2> oldMap
    ) {
        if (newProducts == null || newProducts.isEmpty()) return;
        
        Pricebook2 standardPB = [
            SELECT Id, IsActive
            FROM Pricebook2
            WHERE IsStandard = true
            LIMIT 1
        ];
        
        if (!standardPB.IsActive) {
            standardPB.IsActive = true;
            update standardPB;
        }
        
        List<CurrencyType> activeCurrencies = [
            SELECT IsoCode
            FROM CurrencyType
            WHERE IsActive = true
        ];
        
        Set<Id> productIds = new Set<Id>();
        for (Product2 p : newProducts) {
            if (p.Id != null) {
                productIds.add(p.Id);
            }
        }
        
        Map<String, PricebookEntry> existingMap = new Map<String, PricebookEntry>();
        
        for (PricebookEntry pbe : [
            SELECT Product2Id, CurrencyIsoCode
            FROM PricebookEntry
            WHERE Pricebook2Id = :standardPB.Id
            AND Product2Id IN :productIds
        ]) {
            existingMap.put(pbe.Product2Id + '-' + pbe.CurrencyIsoCode, pbe);
        }
        
        List<PricebookEntry> entriesToInsert = new List<PricebookEntry>();
        
        for (Product2 prod : newProducts) {
            
            // 🔥 REMOVED FLAG CONDITION
            for (CurrencyType curr : activeCurrencies) {
                
                String key = prod.Id + '-' + curr.IsoCode;
                
                if (!existingMap.containsKey(key)) {
                    entriesToInsert.add(new PricebookEntry(
                        Pricebook2Id = standardPB.Id,
                        Product2Id = prod.Id,
                        UnitPrice = 1,
                        UseStandardPrice = false,
                        CurrencyIsoCode = curr.IsoCode,
                        IsActive = true
                    ));
                }
            }
        }
        
        if (!entriesToInsert.isEmpty()) {
            insert entriesToInsert;
        }
    }

}