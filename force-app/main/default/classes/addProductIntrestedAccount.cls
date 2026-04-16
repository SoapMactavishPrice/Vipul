public class addProductIntrestedAccount {
    
    // Fetch Product Interested records
    @AuraEnabled 
    public static List<Product_Interested__c> getProdInterest(String Id, List<Id> existingProductIds) {
        List<Product_Interested__c> piList = [SELECT Id, Vipul_Product_Name__c, Vipul_Product_Name__r.Name, Quantity__c,Packaging__c, Create_Sample_Out__c,
                                              Price__c, Product_Family__c, Add_in_Opportunity__c, Product_Code__c, Name, UOM__c ,
                                              New_Product__c, New_Product_Name__c, New_Product_Description__c, New_Product_CI_No__c,
                                              Sample_Sent_to_Unit__c, Quality__c
                                              FROM Product_Interested__c 
                                              WHERE Account__c = :Id 
                                              AND (Vipul_Product_Name__c NOT IN :existingProductIds OR New_Product__c = true)
                                              ORDER BY CreatedDate];
        return piList;
    }
    
    // Delete Product Interested record
    @AuraEnabled 
    public static String deleteProductInterested(String Id) {
        Product_Interested__c piList = [SELECT Id, Vipul_Product_Name__c, Vipul_Product_Name__r.Name, Quantity__c,Packaging__c, Price__c, Product_Family__c, Add_in_Opportunity__c, 
                                        Product_Code__c, Name, UOM__c, New_Product__c, New_Product_Name__c, New_Product_Description__c, New_Product_CI_No__c, Create_Sample_Out__c,
                                        Sample_Sent_to_Unit__c, Quality__c
                                        FROM Product_Interested__c 
                                        WHERE Id = :Id 
                                        LIMIT 1];
        String pInName = piList.Name;
        delete piList; 
        return 'Product Interested record deleted ' + pInName;
    }
    
    // Fetch existing product IDs for a given Lead
    @AuraEnabled(Cacheable=true)
    public static List<Id> getExistingProducts(String Id) {
        List<Id> ids = new List<Id>();
        List<Product_Interested__c> pi = [SELECT Id, Vipul_Product_Name__c FROM Product_Interested__c WHERE Account__c = :Id AND New_Product__c = false];
        for (Product_Interested__c p : pi) {
            ids.add(p.Vipul_Product_Name__c);
        }
        return ids;       
    }
    
    // Get picklist values for Product Family field
    @AuraEnabled(Cacheable=true)
    public static Map<String, List<Map<String, String>>> getPicklistValues() {
        Map<String, List<Map<String, String>>> allPicklists = new Map<String, List<Map<String, String>>>();
        
        // Packaging picklist
        Schema.DescribeFieldResult packagingField = Product_Interested__c.Packaging__c.getDescribe();
        List<Map<String, String>> packagingList = new List<Map<String, String>>();
        for (Schema.PicklistEntry pickValue : packagingField.getPicklistValues()) {
            packagingList.add(new Map<String, String>{
                'label' => pickValue.getLabel(),
                    'value' => pickValue.getValue()
                    });
        }
        allPicklists.put('packaging', packagingList);
        
        // UOM picklist
        Schema.DescribeFieldResult uomField = Product_Interested__c.UOM__c.getDescribe();
        List<Map<String, String>> uomList = new List<Map<String, String>>();
        for (Schema.PicklistEntry uomPick : uomField.getPicklistValues()) {
            uomList.add(new Map<String, String>{
                'label' => uomPick.getLabel(),
                    'value' => uomPick.getValue()
                    });
        }
        allPicklists.put('uom', uomList);
        
        return allPicklists;
    }
    
    // Save Product Interested records
    @AuraEnabled
    public static Map<String, String> saveProductInterested(Id Id, String JS) {
        System.debug('Id: ' + Id);
        System.debug('JS: ' + JS);
        Map<String, String> result = new Map<String, String>();
        try {
            List<Product_Interested__c> piList = new List<Product_Interested__c>();
            
            // Deserialize the JS data
            List<Object> jsList = (List<Object>) JSON.deserializeUntyped(JS);
            
            // Fetch the Lead record to determine its currency
            Account accountRecord = [SELECT Id, CurrencyIsoCode FROM Account WHERE Id = :Id LIMIT 1];
            String accountCurrency = accountRecord.CurrencyIsoCode;
            
            // Iterate over the incoming product interested records and set fields
            for (Object obj : jsList) {
                Map<String, Object> objMap = (Map<String, Object>) obj;
                Product_Interested__c pm = new Product_Interested__c();
                
                // Set the Product Interested fields
                if (String.isNotBlank((String) objMap.get('inId'))) {
                    pm.Id = (Id) objMap.get('inId');
                }
                pm.Account__c = Id;  // Link Product_Interested__c to the Lead
                //pm.Vipul_Product_Name__c = (Id) objMap.get('prodId');
                
                pm.New_Product__c = Boolean.valueOf(objMap.get('New_Product__c'));
                
                if (pm.New_Product__c) {
                    
                    // Handle new product fields
                    pm.New_Product_Name__c = (String)objMap.get('New_Product_Name__c');
                    pm.New_Product_CI_No__c = (String)objMap.get('New_Product_CI_No__c');
                    
                    // Convert the product name to uppercase before saving
                    if (pm.New_Product_Name__c != null) {
                        pm.New_Product_Name__c = pm.New_Product_Name__c.toUpperCase();
                    }
                    pm.New_Product_Description__c = (String)objMap.get('New_Product_Description__c');
                    pm.Vipul_Product_Name__c = null;
                } else {
                    pm.Vipul_Product_Name__c = (Id) objMap.get('prodId');
                }
                
                // Handle Quantity field, which should be a Double
                if (objMap.containsKey('volume') && objMap.get('volume') != null) {
                    String volumeStr = objMap.get('volume').toString();
                    if (String.isNotBlank(volumeStr)) {
                        try {
                            pm.Quantity__c = Double.valueOf(volumeStr);
                        } catch (Exception ex) {
                            pm.Quantity__c = null; // or handle the error as needed
                        }
                    } else {
                        pm.Quantity__c = null;
                    }
                }
                
                pm.Quality__c = (String)objMap.get('quality');
                
                // Handle Price field (optional)
                if (objMap.containsKey('price') && objMap.get('price') != null) {
                    String priceStr = objMap.get('price').toString();
                    if (String.isNotBlank(priceStr)) {
                        pm.Price__c = Double.valueOf(priceStr);
                    } else {
                        pm.Price__c = null;  // Set null if price is not available
                    }
                }
                
                pm.Packaging__c = (String) objMap.get('packaging');
                pm.UOM__c = (String) objMap.get('uom');
                pm.Product_Family__c = (String) objMap.get('prodFamily');
                
                // Set the currency to match the related Lead's currency
                pm.CurrencyIsoCode = accountCurrency;  // Set the CurrencyIsoCode field from the related Lead
                
                piList.add(pm);
            }
            
            // Upsert the Product_Interested__c records
            if (piList.size() > 0) {
                upsert piList;
            }
            
            result.put('message', 'success');
        } catch (Exception e) {
            System.debug(e);
            result.put('message', e.getLineNumber() + ' - ' + e.getMessage());
        }
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getaccountCurrency(Id accountId) {
        Account ld = [SELECT CurrencyIsoCode FROM Account WHERE Id = :accountId LIMIT 1];
        return ld.CurrencyIsoCode;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Unit_Master__c> getUnits() {
        return [SELECT Id, Name FROM Unit_Master__c ORDER BY Name];
    }

}