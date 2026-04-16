public with sharing class OrderController {
    @AuraEnabled(cacheable=true)
    public static List<Order> getOrders(Id accountId) {
        return [SELECT Id, Name, OrderNumber, Status, EffectiveDate 
                FROM Order 
                WHERE AccountId = :accountId 
                ORDER BY EffectiveDate DESC];
    }
    
    @AuraEnabled
    public static Map<String, Object> getOrderDetails(Id orderId) {
        Order ord = [SELECT Id, AccountId, Country__c, Order_Type__c, Inco_Terms__c, 
                     Payment_Terms__c, CurrencyIsoCode, /*Status,*/ Order_Source__c, 
                     /*EffectiveDate,*/ PoNumber, PoDate 
                     FROM Order WHERE Id = :orderId LIMIT 1];
        
        List<OrderItem> items = [SELECT Id, Product2Id, Quantity, UnitPrice, ListPrice,
                                 Quality__c, Commission_Type__c, Commission_Value__c,
                                 Commission_Percent__c, Freight_Value__c,
                                 Total_Price__c
                                 FROM OrderItem WHERE OrderId = :orderId];
        
        return new Map<String, Object>{
            'order' => ord,
                'orderItems' => items
                };
                    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getOrderPicklistValues() {
        List<Map<String, String>> results = new List<Map<String, String>>();
        
        // For Order fields
        Schema.DescribeSObjectResult orderDescribe = Order.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> orderFields = orderDescribe.fields.getMap();
        
        List<String> orderFieldList = new List<String>{'CurrencyIsoCode', 'Status'};
            for (String fieldName : orderFieldList) {
                Schema.DescribeFieldResult fieldResult = orderFields.get(fieldName).getDescribe();
                for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                    results.add(new Map<String, String>{
                        'field' => fieldName,
                            'label' => entry.getLabel(),
                            'value' => entry.getValue()
                            });
                }
            }
        
        // For OrderItem fields (like Commission_Type__c)
        Schema.DescribeSObjectResult itemDescribe = OrderItem.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> itemFields = itemDescribe.fields.getMap();
        
        List<String> itemFieldList = new List<String>{'Commission_Type__c', 'Packaging__c', 'Packing_Type__c'};
            for (String fieldName : itemFieldList) {
                Schema.DescribeFieldResult fieldResult = itemFields.get(fieldName).getDescribe();
                for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                    results.add(new Map<String, String>{
                        'field' => fieldName,
                            'label' => entry.getLabel(),
                            'value' => entry.getValue()
                            });
                }
            }
        
        return results;
    }
    
    
    @AuraEnabled
    public static Id createOrUpdateOrder(Id accountId, String orderFields, String orderLineItems) {
        try {
            
            Map<String, Object> fields = (Map<String, Object>) JSON.deserializeUntyped(orderFields);
            List<Object> rawList = (List<Object>) JSON.deserializeUntyped(orderLineItems);
            
            List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
            for (Object obj : rawList) {
                lineItems.add((Map<String, Object>) obj);
            }
            
            /* -----------------------------
Fetch Account with RecordType
----------------------------- */
            
            Account acc = [
                SELECT Id, Country__c, Buyer_s_Ref_PO__c, Buyer_s_PO_Date__c,
                RecordType.DeveloperName
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];
            
            String accRT = acc.RecordType.DeveloperName;
            
            /* -----------------------------
Fetch Location
----------------------------- */
            
            Map<String, Id> locationByName = new Map<String, Id>();
            
            for (Location__c l : [
                SELECT Id, Name
                FROM Location__c
                WHERE Name IN ('Andheri HO', 'Ambernath Factory')
            ]) {
                locationByName.put(l.Name, l.Id);
            }
            
            /* -----------------------------
Fetch Warehouse
----------------------------- */
            
            Map<String, Id> warehouseByName = new Map<String, Id>();
            
            for (Unit_Master__c u : [
                SELECT Id, Name
                FROM Unit_Master__c
                WHERE Name IN ('HO_BH_FT', 'AMB_FG_M')
            ]) {
                warehouseByName.put(u.Name, u.Id);
            }
            
            /* -----------------------------
Determine Location/Warehouse
----------------------------- */
            
            Id locationId =
                accRT == 'International'
                ? locationByName.get('Andheri HO')
                : locationByName.get('Ambernath Factory');
            
            Id warehouseId =
                accRT == 'International'
                ? warehouseByName.get('HO_BH_FT')
                : warehouseByName.get('AMB_FG_M');
            
            /* -----------------------------
Fetch Standard Pricebook
----------------------------- */
            
            Pricebook2 standardPB = [
                SELECT Id
                FROM Pricebook2
                WHERE IsStandard = TRUE
                AND IsActive = TRUE
                LIMIT 1
            ];
            
            /* -----------------------------
Create Order
----------------------------- */
            
            Order ord = new Order();
            
            ord.AccountId = accountId;
            ord.Pricebook2Id = standardPB.Id;
            ord.Country__c = acc.Country__c;
            ord.PoNumber = acc.Buyer_s_Ref_PO__c;
            ord.PoDate = acc.Buyer_s_PO_Date__c;
            
            // Tag Location
            ord.Location__c = locationId;
            
            for (String key : fields.keySet()) {
                
                Object val = fields.get(key);
                
                if (key == 'Id') {
                    continue;
                }
                else if (key == 'EffectiveDate' && val != null) {
                    ord.EffectiveDate = Date.valueOf((String)val);
                }
                else if (key == 'PoDate' && val != null) {
                    
                    String dateStr = (String)val;
                    
                    if (!String.isBlank(dateStr)) {
                        ord.PoDate = Date.valueOf(dateStr);
                    }
                }
                else if (key == 'CurrencyIsoCode' && val != null) {
                    ord.CurrencyIsoCode = (String)val;
                }
                else if (val != null) {
                    ord.put(key, val);
                }
            }
            
            insert ord;
            
            /* -----------------------------
Create Order Items
----------------------------- */
            
            List<OrderItem> oiList = new List<OrderItem>();
            
            for (Map<String, Object> item : lineItems) {
                
                String prodId = (String)item.get('prodId');
                
                List<PricebookEntry> pbeList = [
                    SELECT Id, UnitPrice
                    FROM PricebookEntry
                    WHERE Pricebook2Id = :standardPB.Id
                    AND Product2Id = :prodId
                    AND CurrencyIsoCode = :ord.CurrencyIsoCode
                    LIMIT 1
                ];
                
                if (pbeList.isEmpty()) {
                    throw new AuraHandledException(
                        'No Pricebook Entry found for Product: ' +
                        prodId +
                        ' with Currency: ' +
                        ord.CurrencyIsoCode
                    );
                }
                
                OrderItem oi = new OrderItem();
                
                oi.OrderId = ord.Id;
                oi.PricebookEntryId = pbeList[0].Id;
                oi.Product2Id = prodId;
                
                // Tag Warehouse
                oi.Warehouse__c = warehouseId;
                
                oi.Quantity =
                    item.containsKey('Quantity')
                    ? Decimal.valueOf(String.valueOf(item.get('Quantity')))
                    : null;
                
                oi.UnitPrice =
                    item.containsKey('UnitPrice')
                    ? Decimal.valueOf(String.valueOf(item.get('UnitPrice')))
                    : pbeList[0].UnitPrice;
                
                if (item.containsKey('CommissionType')) {
                    oi.Commission_Type__c = (String)item.get('CommissionType');
                }
                
            /*    if (item.containsKey('commissionper')) {
                    oi.Commission_Percent__c =
                        Decimal.valueOf(String.valueOf(item.get('commissionper')));
                }	*/
                
                if (item.containsKey('commissionper')) {
                    String value = String.valueOf(item.get('commissionper'));
                    if (String.isNotBlank(value)) {  // This checks for null, empty, and whitespace
                        try {
                            oi.Commission_Percent__c = Decimal.valueOf(value);
                        } catch (Exception e) {
                            System.debug('Invalid commission percent: ' + value);
                            oi.Commission_Percent__c = null;
                        }
                    }
                }
                
            /*    if (item.containsKey('commissionval')) {
                    oi.Commission_Value__c =
                        Decimal.valueOf(String.valueOf(item.get('commissionval')));
                }		*/
                
                if (item.containsKey('commissionval')) {
    String value = String.valueOf(item.get('commissionval'));
    if (String.isNotBlank(value)) {
        try {
            oi.Commission_Value__c = Decimal.valueOf(value);
        } catch (Exception e) {
            System.debug('Invalid commission value: ' + value);
            oi.Commission_Value__c = null;
        }
    }
}
                
                if (item.containsKey('quality')) {
                    oi.Quality__c = (String)item.get('quality');
                }
                
                if (item.containsKey('freightval') && item.get('freightval') != null) {
                    
                    String freightVal = String.valueOf(item.get('freightval')).trim();
                    
                    if (!String.isBlank(freightVal)) {
                        try {
                            oi.Freight_Value__c = Decimal.valueOf(freightVal);
                        } catch (Exception e) {
                            oi.Freight_Value__c = null;
                        }
                    }
                }
                
              /*  if (item.containsKey('discountval')) {
                    oi.Discount__c =
                        Decimal.valueOf(String.valueOf(item.get('discountval')));
                }		*/
                
                
                if (item.containsKey('discountval')) {
                    String value = String.valueOf(item.get('discountval'));
                    if (String.isNotBlank(value)) {
                        try {
                            oi.Discount__c = Decimal.valueOf(value);
                        } catch (Exception e) {
                            System.debug('Invalid discount: ' + value);
                            oi.Discount__c = null;
                        }
                    }
                }
                
                
                
                if (item.containsKey('PackagingType')) {
                    oi.Packaging__c = (String)item.get('PackagingType');
                }
                
                if (item.containsKey('PackagingTypeValues')) {
                    oi.Packing_Type__c = (String)item.get('PackagingTypeValues');
                }
                
                oiList.add(oi);
            }
            
            if (!oiList.isEmpty()) {
                insert oiList;
            }
            
            return ord.Id;
            
        } catch (Exception e) {
            
            throw new AuraHandledException(
                'Error: ' + e.getMessage() + ' Line: ' + e.getLineNumber()
            );
        }
    }
    
    
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getUserInfoWithOrderType() {
        Map<String, Object> result = new Map<String, Object>();
        
        // Get user info
        User currentUser = [SELECT Id, Profile.Name, User_Division__c FROM User WHERE Id = :UserInfo.getUserId()];
        result.put('userInfo', new Map<String, String>{
            'ProfileName' => currentUser.Profile.Name,
                'UserDivision' => currentUser.User_Division__c
                });
        
        // Get Order Type picklist values
        result.put('filteredPicklist', getPicklistValues('Order', 'Order_Type__c'));
        
        // Get Commission Type picklist values if needed
        result.put('commissionTypeOptions', getPicklistValues('OrderItem', 'Commission_Type__c'));
        
        // ✅ Get Packaging picklist values
    	result.put('packagingTypeOptions', getPicklistValues('OrderItem', 'Packaging__c'));
        
        result.put('optionsPackagingTypeValuesOption', getPicklistValues('OrderItem', 'Packing_Type__c'));
        
        return result;
    }
    
    // Helper method to get picklist values
    private static List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .fields.getMap()
            .get(fieldName)
            .getDescribe();
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                        'value' => entry.getValue()
                        });
            }
        }
        
        return options;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Check_List__c> getCheckListsByAccount(Id accountId) {
        List<Check_List__c> results = [
            SELECT Id FROM Check_List__c WHERE Account__c = :accountId ORDER BY CreatedDate DESC
        ];
        return results != null ? results : new List<Check_List__c>(); // 👈 Ensure always returns a list
    }
    
    
    
}