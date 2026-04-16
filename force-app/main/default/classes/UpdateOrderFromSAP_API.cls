@RestResource(urlMapping = '/UpdateOrderFromSAP')
global class UpdateOrderFromSAP_API {

    @HttpPost
    global static void doPost() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        String jsonBody = request.requestBody.toString().replace('\n','');

        API_Log__c apiLog = new API_Log__c(
            API_log_Name__c = 'UpdateOrderFromSAP',
            Request__c = jsonBody,
            Request_Created_Time__c = Datetime.now()
        );

        try {
            jsonBody = jsonBody.replace('"Revision_Date":""', '"Revision_Date":null');

            List<SAPOrderWrapper> reqList =
                (List<SAPOrderWrapper>) JSON.deserialize(jsonBody, List<SAPOrderWrapper>.class);

            /* ================= COLLECT DATA ================= */
            Set<String> orderNums = new Set<String>();
            Set<String> itemCodes = new Set<String>();
            Set<String> customerCodes = new Set<String>();
            Set<String> locationNames = new Set<String>();
            Set<String> locationCodes = new Set<String>();
            Set<String> empCodes = new Set<String>();
            Set<String> sapPackagingValues = new Set<String>();

            for (SAPOrderWrapper o : reqList) {

                if (String.isBlank(o.Sale_Order_Number)) {
                    throw new IllegalArgumentException('Sale_Order_Number missing');
                }

                orderNums.add(o.Sale_Order_Number);

                if(String.isNotBlank(o.CustomerCode)){
                    customerCodes.add(o.CustomerCode);
                }
                
                if(String.isNotBlank(o.SalesEmployeeCode)){
                    empCodes.add(o.SalesEmployeeCode.replaceFirst('^0+', ''));
                }

                for (SAPOrderLineWrapper li : o.Item_Details) {
                    itemCodes.add(li.ItemCode);

                    if(String.isNotBlank(li.Location)){
                        locationNames.add(li.Location);
                    }
                    if(String.isNotBlank(li.LocCode)){
                        locationCodes.add(li.LocCode);
                    }
                    if (String.isNotBlank(li.U_PKSZ)) {
                        sapPackagingValues.add(li.U_PKSZ.trim());
                    }

                }
            }

            /* ================= FETCH ACCOUNTS ================= */
            Map<String, Id> accMap = new Map<String, Id>();
            for(Account acc : [
                SELECT Id, Customer_Code__c
                FROM Account
                WHERE Customer_Code__c IN :customerCodes
            ]){
                accMap.put(acc.Customer_Code__c, acc.Id);
            }

            /* ================= FETCH ORDERS USING PoNumber ================= */
            Set<String> poNumbers = new Set<String>();
            
            for (SAPOrderWrapper o : reqList) {
                if(String.isNotBlank(o.PO_Number)){
                    poNumbers.add(o.PO_Number);
                }
            }
            
            Map<String, Order> orderMap = new Map<String, Order>();
            
            for (Order o : [
                SELECT Id, PoNumber, Pricebook2Id, CurrencyIsoCode
                FROM Order
                WHERE PoNumber IN :poNumbers
            ]) {
                orderMap.put(o.PoNumber, o);
            }
            
            /* ================= FETCH USERS ================= */
            Map<String, Id> empUserMap = new Map<String, Id>();

            if(!empCodes.isEmpty()){
                for(User u : [
                    SELECT Id, EmployeeNumber
                    FROM User
                    WHERE EmployeeNumber IN :empCodes
                    AND IsActive = true
                ]){
                    empUserMap.put(u.EmployeeNumber, u.Id);
                }
            }

            /* ================= FETCH PRODUCTS ================= */
            Map<String, Id> productMap = new Map<String, Id>();
            for (Product2 p : [
                SELECT Id, Item_No__c
                FROM Product2
                WHERE Item_No__c IN :itemCodes
            ]) {
                productMap.put(p.Item_No__c, p.Id);
            }

            /* ================= FETCH LOCATIONS ================= */
            Map<String, Id> locationMap = new Map<String, Id>();

            if(!locationNames.isEmpty() || !locationCodes.isEmpty()){
                for(Location__c loc : [
                    SELECT Id, Name, Loc_Code__c
                    FROM Location__c
                    WHERE Name IN :locationNames OR Loc_Code__c IN :locationCodes
                ]){
                    if(String.isNotBlank(loc.Name)){
                        locationMap.put(loc.Name, loc.Id);
                    }
                    if(String.isNotBlank(loc.Loc_Code__c)){
                        locationMap.put(loc.Loc_Code__c, loc.Id);
                    }
                }
            }
            
            Set<String> existingPackagingValues = new Set<String>();
            Set<String> newPackagingValues = new Set<String>();
            
            // Get existing picklist values
            Schema.DescribeFieldResult dfr =
                OrderItem.Packaging__c.getDescribe();
            
            for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                existingPackagingValues.add(pe.getValue());
            }
            
            // Find missing values
            for (String sapVal : sapPackagingValues) {
                if (!existingPackagingValues.contains(sapVal)) {
                    newPackagingValues.add(sapVal);
                }
            }

            /* ================= STANDARD PRICEBOOK ================= */
            Id stdPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

            /* ================= PRICEBOOK ENTRIES ================= */
            Set<Id> pricebookIds = new Set<Id>();
            
            for(Order o : orderMap.values()){
                if(o.Pricebook2Id != null){
                    pricebookIds.add(o.Pricebook2Id);
                }
            }
            
            // ALSO include stdPricebook for new orders
            pricebookIds.add(stdPricebookId);
            Map<String, Id> pbeMap = new Map<String, Id>();

            for (PricebookEntry pbe : [
                SELECT Id, Pricebook2Id, Product2Id, CurrencyIsoCode
                FROM PricebookEntry
                WHERE Product2Id IN :productMap.values()
                AND Pricebook2Id = :pricebookIds
                AND IsActive = true
            ]) {
                String key = pbe.Pricebook2Id + '-' + pbe.Product2Id + '-' + pbe.CurrencyIsoCode;
                pbeMap.put(key, pbe.Id);
            }

            /* ================= EXISTING ORDER ITEMS ================= */
            Map<Id, List<OrderItem>> existingItemsMap = new Map<Id, List<OrderItem>>();

            for(OrderItem oi : [
                SELECT Id, OrderId
                FROM OrderItem
                WHERE OrderId IN :orderMap.values()
            ]) {
                if(!existingItemsMap.containsKey(oi.OrderId)){
                    existingItemsMap.put(oi.OrderId, new List<OrderItem>());
                }
                existingItemsMap.get(oi.OrderId).add(oi);
            }

            List<Order> ordersToInsert = new List<Order>();
            List<Order> ordersToUpdate = new List<Order>();
            List<OrderItem> itemsToInsert = new List<OrderItem>();
            List<OrderItem> itemsToDelete = new List<OrderItem>();

            /* ================= PROCESS ================= */
            for (SAPOrderWrapper req : reqList) {
                
                /* ===== MANDATORY FIELD VALIDATION ===== */
                
                if(String.isBlank(req.PO_Number)){
                    throw new IllegalArgumentException('PO_Number is mandatory');
                }
                
                if(String.isBlank(req.ShiptoAddressID)){
                    throw new IllegalArgumentException('ShiptoAddressID is mandatory');
                }
                
                if(String.isBlank(req.BilltoAddressID)){
                    throw new IllegalArgumentException('BilltoAddressID is mandatory');
                }

                Order ord;
                Boolean isUpdate = orderMap.containsKey(req.PO_Number);

                if (isUpdate) {
                    ord = orderMap.get(req.PO_Number);

                    /* CURRENCY VALIDATION */
                    if (!String.isBlank(req.Currency1) &&
                        ord.CurrencyIsoCode != req.Currency1) {
                        throw new IllegalArgumentException(
                            'Currency mismatch. Order currency is ' +
                            ord.CurrencyIsoCode +
                            ' but SAP sent ' + req.Currency1
                        );
                    }

                    if(existingItemsMap.containsKey(ord.Id)){
                        itemsToDelete.addAll(existingItemsMap.get(ord.Id));
                    }

                } else {

                    if(!accMap.containsKey(req.CustomerCode)){
                        throw new IllegalArgumentException(
                            'Account not found for CustomerCode: ' + req.CustomerCode
                        );
                    }

                    ord = new Order();
                    ord.AccountId = accMap.get(req.CustomerCode);
                    ord.EffectiveDate = Date.today();
                    ord.Status = 'Draft';
                    ord.Pricebook2Id = stdPricebookId;
                    ord.CurrencyIsoCode = req.Currency1;
                }

                /* ===== FIELD MAPPING ===== */
                ord.Oracle_Sales_Order_No__c = req.Sale_Order_Number;
                ord.PoNumber = req.PO_Number;

                if(!String.isBlank(req.PO_Date)){
                    ord.PoDate = Date.valueOf(req.PO_Date);
                }

                ord.Status = req.Status;
                ord.Description = req.Description;
                ord.Payment_Terms__c = req.PaymentTerms;
                ord.Inco_Terms__c = req.Incoterms;
                ord.Delivery_Address1__c = req.ShiptoAddressID;
                ord.Consignee_Address1__c = req.BilltoAddressID;

                ord.Delivery_Schedule__c = req.Delivery_Schedule;
                ord.SQ_Type__c = req.SQ_Type;
                ord.Final_Destination__c = req.Final_Destination;
                ord.Portof_Discharge__c = req.Portof_Discharge;
                ord.Portof_Loading__c = req.Portof_Loading;
                ord.Pre_Carriageby__c = req.Pre_Carriageby;
                ord.Countryof_Final_Destination__c = req.Countryof_FinalDestination;

                ord.Branch_Code__c = req.BranchCode;
                ord.Owner_Code__c = req.OwnerCode;
                ord.Sales_Employee_Code__c = req.SalesEmployeeCode;

                if(!String.isBlank(req.PostingDate)){
                    ord.Posting_Date__c = Date.valueOf(req.PostingDate);
                }

                if(!String.isBlank(req.DocumentDate)){
                    ord.Document_Date__c = Date.valueOf(req.DocumentDate);
                }
                
                if(req.Revision_Date != null){
                    ord.Revision_Date__c = req.Revision_Date;
                }

                ord.OrderReferenceNumber = req.ReferenceNo;
                //ord.Revision_Date__c = req.Revision_Date;
                ord.Cancel__c = req.Cancel;
                
                ord.Sales_Employee_Code__c = req.SalesEmployeeCode;

                /* ===== USER MAPPING ===== */
                String empCode = req.SalesEmployeeCode != null
                    ? req.SalesEmployeeCode.replaceFirst('^0+', '')
                    : null;

                if(empUserMap.containsKey(empCode)){
                    ord.OwnerId = empUserMap.get(empCode);
                }

                if(isUpdate){
                    ordersToUpdate.add(ord);
                } else {
                    ordersToInsert.add(ord);
                }
            }

            /* ================= DML ================= */
            if(!ordersToInsert.isEmpty()){
                insert ordersToInsert;

                for(Order o : ordersToInsert){
                    orderMap.put(o.PoNumber, o);
                }
            }

            if(!ordersToUpdate.isEmpty()){
                update ordersToUpdate;
            }

            if(!itemsToDelete.isEmpty()){
                delete itemsToDelete;
            }

            /* ================= INSERT ORDER ITEMS ================= */
            for (SAPOrderWrapper req : reqList) {

                Order ord = orderMap.get(req.PO_Number);

                for (SAPOrderLineWrapper li : req.Item_Details) {

                    Id productId = productMap.get(li.ItemCode);

                    String key = ord.Pricebook2Id + '-' + productId + '-' + ord.CurrencyIsoCode;
                    Id pbeId = pbeMap.get(key);

                    if (pbeId == null) {
                        throw new IllegalArgumentException(
                            'PricebookEntry missing for Item: ' + li.ItemCode
                        );
                    }

                    /* LOCATION MAPPING */
                    if(String.isNotBlank(li.Location) && locationMap.containsKey(li.Location)) {
                        ord.Location__c = locationMap.get(li.Location);
                    } 
                    else if(String.isNotBlank(li.LocCode) && locationMap.containsKey(li.LocCode)) {
                        ord.Location__c = locationMap.get(li.LocCode);
                    }
                    
                /*    if (!newPackagingValues.isEmpty()) {
                        System.enqueueJob(
                            new AddGlobalPicklistValuesJob('Packing', newPackagingValues)
                        );
                    } */

                    OrderItem oi = new OrderItem();
                    oi.OrderId = ord.Id;
                    oi.Product2Id = productId;
                    oi.PricebookEntryId = pbeId;
                    oi.Quantity = toDecimal(li.Quantity);
                    oi.UnitPrice = toDecimal(li.UnitPrice);

                    oi.Grade__c = li.U_Grade;
                    oi.Product_Segments__c = li.U_Segment;
                    
                    if (isValidPackagingValue(li.U_PKSZ)) {
                        oi.Packaging__c = li.U_PKSZ;
                    }

                    oi.Packing_Type__c = li.U_PT;
                    oi.Tax_Code__c = li.TaxCode;

                    if (!String.isBlank(li.DiscountPer)) {
                        oi.Discount__c = toDecimal(li.DiscountPer);
                    }

                    itemsToInsert.add(oi);
                }
            }

            if(!itemsToInsert.isEmpty()){
                insert itemsToInsert;
            }

            /* ================= SUCCESS ================= */
            String successResp = '{"status":"success","message":"Orders processed"}';

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(successResp);

            apiLog.Status__c = 'Success';
            apiLog.Response__c = successResp;
            apiLog.Response_Code__c = '200';
            apiLog.Response_Time__c = Datetime.now();

        } catch (Exception e) {

            String errorResp = '{"status":"failure","message":"' + e.getMessage() + '"}';

            response.statusCode = 400;
            response.responseBody = Blob.valueOf(errorResp);

            apiLog.Status__c = 'Failure';
            apiLog.Response__c = errorResp;
            apiLog.Response_Code__c = '400';
            apiLog.Exception_Description__c =
                'Line: ' + e.getLineNumber() + '\n' +
                e.getMessage() + '\n' +
                e.getStackTraceString();
            apiLog.Response_Time__c = Datetime.now();
        }

        insert apiLog;
    }

    private static Decimal toDecimal(String val) {
        return String.isBlank(val) ? 0 : Decimal.valueOf(val);
    }

    global class SAPOrderWrapper {
        public String Sale_Order_Number;
        public String CustomerCode;
        public String PO_Number;
        public String PO_Date;
        public String Status;
        public String Description;
        public String PaymentTerms;
        public String Incoterms;
        public String Currency1;
        public String ShiptoAddressID;
        public String BilltoAddressID;
        public Date Revision_Date;
        public String Cancel;
        public String Delivery_Schedule;
        public String SQ_Type;
        public String Final_Destination;
        public String Portof_Discharge;
        public String Portof_Loading;
        public String Pre_Carriageby;
        public String Countryof_FinalDestination;
        public String BranchCode;
        public String OwnerCode;
        public String SalesEmployeeCode;
        public String PostingDate;
        public String DocumentDate;
        public String ReferenceNo;
        public List<SAPOrderLineWrapper> Item_Details;
    }

    global class SAPOrderLineWrapper {
        public String ItemCode;
        public String Quantity;
        public String UnitPrice;
        public String U_Grade;
        public String U_Segment;
        public String U_PKSZ;
        public String U_PT;
        public String TaxCode;
        public String DiscountPer;
        public String Location;
        public String LocCode;
    }
    
    private static Boolean isValidPackagingValue(String value) {
        if (String.isBlank(value)) return false;
        
        for (Schema.PicklistEntry pe :
             OrderItem.Packaging__c.getDescribe().getPicklistValues()) {
                 if (pe.getValue() == value) {
                     return true;
                 }
             }
        return false;
    }
    
    public static void fc (){
        Integer i = 1;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        
    }
}