public class GetItemStock_FromSAP {

    public static void getItemStockData(){

        Date todayDate = Date.today();
        DateTime todayDateTime = DateTime.newInstance(todayDate, Time.newInstance(0, 0, 0, 0));
        String formatted_T_Date = todayDateTime.format('yyyyMMdd');

        API_Log__c api_log = new API_Log__c();
        api_log.API_log_Name__c = 'GetItemStock_FromSAP';
        api_log.Request_Created_Time__c = Datetime.now();

        try {

            HttpRequest req = new HttpRequest();
            Http http = new Http();

            String endpointURL = Label.ItemStockEndpoint + formatted_T_Date;
            api_log.Request__c = endpointURL;

            req.setEndpoint(endpointURL);
            req.setMethod('GET');
            req.setTimeout(120000);

            HttpResponse res = http.send(req);
            String jsonBody = res.getBody();
            api_log.Response__c = jsonBody;

            if (res.getStatusCode() == 200) {

                List<Item_Stock__c> insertItemStock = new List<Item_Stock__c>();
                List<Item_Stock__c> deleteItemStock = new List<Item_Stock__c>();

                // Deserialize
                List<ItemStockResponse> itemStocksList =
                    (List<ItemStockResponse>) JSON.deserialize(jsonBody, List<ItemStockResponse>.class);

                // ================= PRODUCT MAP =================
                Set<String> productCodeSet = new Set<String>();
                for (ItemStockResponse itemStock : itemStocksList) {
                    productCodeSet.add(normalizeKey(itemStock.ItemCode));
                }

                Map<String, Id> mapProductId = new Map<String, Id>();

                for (Product2 p : [
                    SELECT Id, Item_No__c
                    FROM Product2
                    WHERE Item_No__c != null
                ]) {
                    mapProductId.put(normalizeKey(p.Item_No__c), p.Id);
                }

                // ================= UNIT MASTER MAP =================
                Map<String, Id> umMap = new Map<String, Id>();

                for (Unit_Master__c um : [
                    SELECT Id, Name
                    FROM Unit_Master__c
                    WHERE Name != null
                ]) {
                    umMap.put(normalizeKey(um.Name), um.Id);
                }

                // ================= EXISTING STOCK =================
                List<Item_Stock__c> exItemStockList = [
                    SELECT Id, Item_Code__c, Unit_Master__c
                    FROM Item_Stock__c
                    WHERE Item_Code__c != null
                ];

                Map<String, Item_Stock__c> exItemStockMap = new Map<String, Item_Stock__c>();

                for (Item_Stock__c isRec : exItemStockList) {
                    String key = normalizeKey(isRec.Item_Code__c) + isRec.Unit_Master__c;
                    exItemStockMap.put(key, isRec);
                }

                // ================= MAIN LOOP =================
                for (ItemStockResponse v : itemStocksList) {

                    String itemKey = normalizeKey(v.ItemCode);
                    String whsKey  = normalizeKey(v.WhsCode);

                    // DEBUG (keep temporarily)
                    System.debug('Incoming Item: [' + v.ItemCode + '] -> ' + itemKey);
                    System.debug('Incoming WH: [' + v.WhsCode + '] -> ' + whsKey);

                    if (umMap.containsKey(whsKey) && mapProductId.containsKey(itemKey)) {

                        Item_Stock__c newItemStock = new Item_Stock__c();

                        newItemStock.Name = v.ItemCode + ' - ' + v.WhsCode;
                        newItemStock.Item_Code__c = v.ItemCode;
                        newItemStock.Unit_Master__c = umMap.get(whsKey);
                        newItemStock.Product__c = mapProductId.get(itemKey);

                        // Safe numeric parsing
                        newItemStock.On_Hand__c      = parseDecimal(v.OnHand);
                        newItemStock.Quantity__c     = parseDecimal(v.OpeningQty);
                        newItemStock.In_Quantity__c  = parseDecimal(v.InQty);
                        newItemStock.Out_Quantity__c = parseDecimal(v.OutQty);
                        newItemStock.Stock_Rate__c   = v.StockRate == null ? 0 : v.StockRate;

                        insertItemStock.add(newItemStock);

                        String existingKey = itemKey + newItemStock.Unit_Master__c;

                        if (exItemStockMap.containsKey(existingKey)) {
                            deleteItemStock.add(exItemStockMap.get(existingKey));
                        }

                    } else {
                        System.debug('❌ SKIPPED => Item: [' + v.ItemCode + '] WH: [' + v.WhsCode + ']');
                        System.debug('👉 Available WH Keys: ' + umMap.keySet());
                        System.debug('👉 Available Product Keys: ' + mapProductId.keySet());
                    }
                }

                // ================= DML =================
                System.debug('✅ Records to Insert: ' + insertItemStock.size());

                if (!insertItemStock.isEmpty()) {
                    insert insertItemStock;

                    if (!deleteItemStock.isEmpty()) {
                        delete deleteItemStock;
                    }
                }

            } else {
                api_log.Status__c = 'Failure';
                api_log.Response_Code__c = String.valueOf(res.getStatusCode());
            }

        } catch (Exception e) {

            api_log.Status__c = 'Failure';
            api_log.Response_Code__c = '400';
            api_log.Exception_Description__c =
                'Line: ' + e.getLineNumber() + '\n' + e.getMessage() + '\n' + e.getStackTraceString();

            api_log.Response_Time__c = Datetime.now();
        }

        insert api_log;
    }

    // ================= HELPER METHODS =================

    public static String normalizeKey(String input) {
        if (input == null) return null;

        // remove ALL whitespace (spaces, tabs, hidden chars)
        String cleaned = input.replaceAll('\\s+', '');

        return cleaned.trim().toUpperCase();
    }

    public static Decimal parseDecimal(String val) {
        if (String.isBlank(val)) return 0;
        try {
            return Decimal.valueOf(val);
        } catch (Exception e) {
            return 0;
        }
    }

    // ================= RESPONSE CLASS =================

    public class ItemStockResponse {
        public String ItemCode;
        public String WhsCode;
        public String OnHand;
        public String InventoryItem;
        public String SaleItem;
        public String OpeningQty;
        public String InQty;
        public String OutQty;
        public Decimal StockRate; // FIXED
    }
}




/*public class GetItemStock_FromSAP {

    public static void getItemStockData(){

        Date todayDate = Date.today();
        DateTime todayDateTime = DateTime.newInstance(todayDate, Time.newInstance(0, 0, 0, 0));

        String formatted_T_Date = todayDateTime.format('yyyyMMdd');
        System.debug(formatted_T_Date);

        API_Log__c api_log = new API_Log__c();
        api_log.API_log_Name__c = 'GetItemStock_FromSAP';
        api_log.Request_Created_Time__c = Datetime.now();

        try {

            // Initialize the HTTP request
            HttpRequest req = new HttpRequest();
            Http http = new Http();

            String endpointURL = label.ItemStockEndpoint+''+formatted_T_Date;
            // String endpointURL = label.ItemStockEndpoint+'20250824';
            api_log.Request__c = endpointURL;

            // Set the endpoint (URL)
            req.setEndpoint(endpointURL);
            req.setMethod('GET');
            req.setTimeout(120000);

            // Set headers
            // req.setHeader('SOAPAction', apiparam.SOAPAction);
            // req.setHeader('Content-Type', apiparam.ContentType);
            // req.setHeader('Authorization', HttpUtils.createBasicAuthHeader(apiparam.Username, apiparam.Password));

            HttpResponse res = http.send(req);

            // System.debug(res.getBody());

            String jsonBody = res.getBody();
            api_log.Response__c = jsonBody;

            if (res.getStatusCode() == 200) {

                List<Item_Stock__c> insertItemStock = new List<Item_Stock__c>();
                List<Item_Stock__c> deleteItemStock = new List<Item_Stock__c>();

                // Parse the JSON
                List<ItemStockResponse> itemStocksList = (List<ItemStockResponse>)JSON.deserialize(jsonBody, List<ItemStockResponse>.class);

                Set<String> productCodeSet = new Set<String>();
                for(ItemStockResponse itemStock : itemStocksList) {
                    productCodeSet.add(itemStock.ItemCode);
                }

                List<Product2> productListByCode = [
                    SELECT Id, Item_No__c
                    FROM Product2
                    WHERE Item_No__c IN :productCodeSet
                ];

                Map<String, String> mapProductId = new Map<String, String>();
                for (Product2 p : productListByCode) {
                    mapProductId.put(p.Item_No__c, p.Id);
                }

                // Get existing Item stock records
                List<Item_Stock__c> exItemStockList = [
                    SELECT Id, Name, Product__c, Unit_Master__c, Unit_Master__r.Name, Item_Code__c
                    FROM Item_Stock__c
                    WHERE Item_Code__c IN: productCodeSet
                    AND Unit_Master__c != null
                ];

                Map<String, Item_Stock__c> exItemStockMap = new Map<String, Item_Stock__c>();
                for (Item_Stock__c is : exItemStockList) {
                    exItemStockMap.put(is.Item_Code__c+is.Unit_Master__c, is);
                }

                // Get warehouse master data
                List<Unit_Master__c> umList = [
                    SELECT Id, Name
                    FROM Unit_Master__c
                    WHERE Name != null
                ];

                Map<String, String> umMap = new Map<String, String>();

                for (Unit_Master__c um : umList) {
                    umMap.put(um.Name, um.Id);
                }

                // Insert/Delete Item Stock
                if (itemStocksList.size() > 0) {
                    for (ItemStockResponse v : itemStocksList) {
                        if (umMap.containsKey(v.WhsCode) && mapProductId.containsKey(v.ItemCode)) {
                            Item_Stock__c newItemStock = new Item_Stock__c();
                            newItemStock.Name = v.ItemCode+' - '+v.WhsCode;
                            newItemStock.Item_Code__c = v.ItemCode;
                            newItemStock.Unit_Master__c = umMap.get(v.WhsCode);
                            newItemStock.Product__c = mapProductId.get(v.ItemCode);
                            // if (umMap.containsKey(v.WhsCode) != null) {
                            //     newItemStock.Unit_Master__c = umMap.get(v.WhsCode);
                            // } else {
                            //     throw new IllegalArgumentException('Warehouse Code '+v.WhsCode+' not found');
                            // }
                            // if (mapProductId.get(v.ItemCode) != null) {
                            //     newItemStock.Product__c = mapProductId.get(v.ItemCode);
                            // } else {
                            //     throw new IllegalArgumentException('Item Code '+v.ItemCode+' not found');
                            // }
                            newItemStock.On_Hand__c = String.isBlank(v.OnHand) ? 0 : Decimal.valueOf(v.OnHand);
                            newItemStock.Quantity__c = Decimal.valueOf(v.OpeningQty);
                            newItemStock.In_Quantity__c = Decimal.valueOf(v.InQty);
                            newItemStock.Out_Quantity__c = Decimal.valueOf(v.OutQty);
                            newItemStock.Stock_Rate__c = Decimal.valueOf(v.StockRate);
                            insertItemStock.add(newItemStock);
                            if (exItemStockMap.containsKey(newItemStock.Item_Code__c+newItemStock.Unit_Master__c)) {
                                deleteItemStock.add(exItemStockMap.get(newItemStock.Item_Code__c+newItemStock.Unit_Master__c));   
                            }
                        } else {
                            System.debug('Skipping record: ' + v.ItemCode + ' / ' + v.WhsCode);
                        }
                    }
    
                    if (insertItemStock.size() > 0) {
                        insert insertItemStock;
                        if (deleteItemStock.size() > 0) {
                            delete deleteItemStock;
                        }
                    }
                }

            } else {
                api_log.Status__c = 'Failure';
                api_log.Response_Code__c = String.valueOf(res.getStatusCode());
            }

        } catch (Exception e) {
            System.debug('Catch Error' + e.getStackTraceString());
            System.debug('Catch Error' + e.getMessage());
            System.debug('Catch Error' + e.getlineNumber());
            
            api_log.Status__c = 'Failure';
            api_log.Response_Code__c = '400';
            api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            api_log.response_time__c = Datetime.now();
            
        }
        
        insert api_log;

    }

    public class ItemStockResponse {
        public String ItemCode; 
        public String WhsCode; 
        public String OnHand;
        public String InventoryItem;
        public String SaleItem;
        public String OpeningQty;
        public String InQty;
        public String OutQty;
        public String StockRate;
    }

}*/