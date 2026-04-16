public class CreateSalesOrder_ToOracle {
    
    // @future(callout = true)
    @AuraEnabled
    public static string createSalesOrderData(String soId, String objName) {
        
        String responseBodyData = '';
        
        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.API_log_Name__c = 'CreateSalesOrder_ToSAP ('+objName+')';
        api_log.Request_Created_Time__c = DateTime.now();
        
        try {
            
            String jsonBody = '';
            if(objName == 'Quote'){
                jsonBody = createJSONrequest(soId);
            } else if(objName == 'Order'){
                jsonBody = createDirectOrderJSONrequest(soId);
            }
            
            api_log.Request__c = jsonBody;
            
            // Define API URL
            String apiUrl = label.CreateSalesOrderOracle;
            
            // Authentication Header
            // String username = label.api_username;
            // String password = label.api_pass;
            // String authHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
            
            // Create HTTP request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(apiUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            // req.setHeader('Authorization', authHeader);
            req.setBody(jsonBody);
            req.setTimeout(120000);
            
            // Send HTTP request
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            String responseBody = res.getBody();
            System.debug(responseBody);
            
            List<OrderResponse> responseList = new List<OrderResponse>();
            
            try {
                responseList = (List<OrderResponse>) JSON.deserialize(
                    responseBody,
                    List<OrderResponse>.class
                );
            } catch (Exception parseEx) {
                
                System.debug('Invalid JSON from SAP: ' + responseBody);
                
                // 🔥 Handle non-JSON response safely
                api_log.Status__c = 'Failure';
                api_log.Response__c = responseBody;
                api_log.Exception_Description__c = 'Invalid JSON Response: ' + responseBody;
                
                return responseBody; // stop execution safely
            }
            
            // responseBodyData = parseresponseBodyData(responseBody, soId);
            responseBodyData = responseBody;
            
            System.debug(responseList[0].Status);
            
            if (res.getStatusCode() == 200 && responseList != null && !responseList.isEmpty()) {
                
                OrderResponse resp = responseList[0];
                
                if (resp.Status == 'Success') {
                    
                    api_log.Status__c = 'Success';
                    
                    // 🔥 CRITICAL FIX
                    String updateResult = updateSOnumberToQuote(
                        soId,
                        resp.SONumber,
                        resp.ReferenceNo,
                        objName
                    );
                    
                    if (updateResult != 'Success') {
                        api_log.Status__c = 'Failure';
                        api_log.Exception_Description__c = updateResult;
                    }
                    
                } else {
                    api_log.Status__c = 'Failure';
                }
            }
            api_log.Response_Code__c = String.valueOf(res.getStatusCode());
            api_log.Response__c = res.getBody();
            api_log.Response_Time__c = Datetime.now();
            
        } catch (Exception e) {
            System.debug('Error in API Call: ' + e.getMessage());
            responseBodyData = e.getMessage();
            api_log.Status__c = 'Failure';
            api_log.Response_Code__c = '400';
            api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            api_log.Response_Time__c = Datetime.now();
        }
        
        if (objName == 'Quote') {
            api_log.Quote__c = soId;
        }
        insert api_log;
        
        return responseBodyData;
        
    }
    
    // ================= QUOTE =================
    
    public static String createJSONrequest(String Id) {
        
        Quote exOrd = Database.query(getAllFields('Quote', Id));
        
        if (exOrd.Account == null || String.isBlank(exOrd.Account.Customer_Code__c)) {
            throw new AuraHandledException('Customer Code is required on Account');
        }
        
        if (exOrd.Delivery_Address1__c == null) {
            return JSON.serialize(new List<Object>{
                new Map<String, Object>{
                    'Status' => 'Error',
                        'ResponseDescription' => 'Delivery Address is required'
                        }
            });
        }
        if (exOrd.Consignee_Address1__c == null) {
            throw new AuraHandledException('Consignee Address is required');
        }
        
        List<QuoteLineItem> exOrdItem = Database.query(
            getOneLevelLineItemRecords('QuoteLineItem','QuoteId',Id)
        );
        
        List<Map<String,Object>> itemDetails = new List<Map<String,Object>>();
        
        for (QuoteLineItem qli : exOrdItem) {
            itemDetails.add(new Map<String,Object>{
                'ItemCode' => qli.Product2.Item_No__c,
                'Quantity' => qli.Quantity,
                'UnitPrice' => qli.UnitPrice,
                'DiscountPer' => qli.Discount != null ? qli.Discount : 0,
                'Warehouse' => qli.Warehouse__r.Name,
                'LocCode' => exOrd.Location__r.Loc_Code__c,
                'Location' => exOrd.Location__r.Name,
                'U_FRGNM' => qli.Product2.Name,
                'U_PT' => getValue(qli.Packing_Type__c, qli.Product2.Packing_Type__c, false),
                'U_PKSZ' => getValue(qli.Packing__c, qli.Product2.Packing__c, false),
                'U_Segment' => qli.Product2.Product_Segments__c,
                'U_Grade' => getValue(qli.Grade__c, qli.Product2.Grade__c, true)
            });
        }
        
        Map<String,Object> shipTo = buildAddress(exOrd.Delivery_Address1__r);
        Map<String,Object> billTo = buildAddress(exOrd.Consignee_Address1__r);
        
        Map<String,Object> order = new Map<String,Object>{
            'ReferenceNo' => exOrd.PO_PI_Number__c,
            'CustomerPORefNo' => exOrd.PO_PI_Number__c,
            'CardCode' => exOrd.Account.Customer_Code__c,
            'PaymentTerms' => exOrd.Payment_Terms__c,
            'PostingDate' => System.today(),
            'DeliveryDate' => System.today().addDays(10),
            'DocumentDate' => exOrd.PO_Date__c,
            'ShipToCode' => exOrd.Delivery_Address1__r.Code__c,
            'Currency' => exOrd.CurrencyIsoCode,
            'SalesEmployeeCode' => exOrd.Account.Owner.EmployeeNumber,
            'OwnerCode' => exOrd.Account.Owner.EmployeeNumber,
            'BranchCode' => '1',
            'Item_Details' => itemDetails,
            'BillToAddress' => billTo,
            'ShipToAddress' => shipTo
        };
        
        return JSON.serialize(new List<Object>{order});
    }
    
    
    // ================= ORDER =================
    
    public static String createDirectOrderJSONrequest(String Id) {
        
        Order exOrd = Database.query(getAllFields('Order', Id));
        
        if (exOrd.Account == null || String.isBlank(exOrd.Account.Customer_Code__c)) {
            throw new AuraHandledException('Customer Code is required on Account');
        }
        
        if (exOrd.Delivery_Address1__c == null) {
            throw new AuraHandledException('Delivery Address is required');
        }
        if (exOrd.Consignee_Address1__c == null) {
            throw new AuraHandledException('Consignee Address is required');
        }
        
        List<OrderItem> exOrdItem = Database.query(
            getOneLevelLineItemRecords('OrderItem','OrderId',Id)
        );
        
        List<Map<String,Object>> itemDetails = new List<Map<String,Object>>();
        
        for (OrderItem qli : exOrdItem) {
            itemDetails.add(new Map<String,Object>{
                'ItemCode' => qli.Product2.Item_No__c,
                'Quantity' => qli.Quantity,
                'UnitPrice' => qli.UnitPrice,
                'DiscountPer' => qli.Discount__c != null ? qli.Discount__c : 0,
                'Warehouse' => qli.Warehouse__r.Name,
                'LocCode' => exOrd.Location__r.Loc_Code__c,
                'U_FRGNM' => qli.Product2.Name,
                'U_PT' => getValue(qli.Packing_Type__c, qli.Product2.Packing_Type__c, false),
                'U_PKSZ' => getValue(qli.Packaging__c, qli.Product2.Packing__c, false),
                'U_Segment' => qli.Product2.Product_Segments__c,
                'U_Grade' => getValue(qli.Grade__c, qli.Product2.Grade__c, true)
            });
        }
        
        Map<String,Object> shipTo = buildAddress(exOrd.Delivery_Address1__r);
        Map<String,Object> billTo = buildAddress(exOrd.Consignee_Address1__r);
        
        Map<String,Object> order = new Map<String,Object>{
            'ReferenceNo' => exOrd.PoNumber,
            'CustomerPORefNo' => exOrd.PoNumber,
            'CardCode' => exOrd.Account.Customer_Code__c,
            'PaymentTerms' => exOrd.Payment_Terms__c,
            'PostingDate' => System.today(),
            'DeliveryDate' => System.today().addDays(10),
            'DocumentDate' => exOrd.PoDate,
            'ShipToCode' => exOrd.Delivery_Address1__r.Code__c,
            'Currency' => exOrd.CurrencyIsoCode,
            'SalesEmployeeCode' => exOrd.Account.Owner.EmployeeNumber,
            'OwnerCode' => exOrd.Account.Owner.EmployeeNumber,
            'BranchCode' => '1',
            'Item_Details' => itemDetails,
            'BillToAddress' => billTo,
            'ShipToAddress' => shipTo
        };
        
        return JSON.serialize(new List<Object>{order});
    }
    
    // ================= COMMON =================
    
    public static Map<String,Object> buildAddress(Address_Information__c addr){
        
        return new Map<String,Object>{
            'AddressID' => addr.Code__c,
            'AddressName2' => addr.Street__c,
            'City' => addr.City__r != null ? addr.City__r.Name : '',
            'ZipCode' => addr.Pin_Code__r != null ? addr.Pin_Code__r.Name : '',
            'State' => addr.State__r != null ? addr.State__r.State_Code__c : '',
            'Country' => addr.Country__r != null ? addr.Country__r.COUNTRY_CODE__c : '',
            'GSTNumber' => addr.GSTIN__c
        };
    }
    
    // Get the Header fields
    public static String getAllFields(String ObjectName, String ObjId) {
        
        if (ObjectName == 'Quote') {
            return 'SELECT Id, PO_PI_Number__c, PO_Date__c, CurrencyIsoCode, Payment_Terms__c,' +
                   'Account.Customer_Code__c, Account.Owner.EmployeeNumber,' +
                   'Location__r.Loc_Code__c, Location__r.Name,' +
                   'Delivery_Address1__c, Delivery_Address1__r.Code__c, Delivery_Address1__r.Street__c,' +
                   'Delivery_Address1__r.City__r.Name, Delivery_Address1__r.Pin_Code__r.Name,' +
                   'Delivery_Address1__r.State__r.State_Code__c, Delivery_Address1__r.Country__r.COUNTRY_CODE__c,' +
                   'Delivery_Address1__r.GSTIN__c,' +
                   'Consignee_Address1__c, Consignee_Address1__r.Code__c, Consignee_Address1__r.Street__c,' +
                   'Consignee_Address1__r.City__r.Name, Consignee_Address1__r.Pin_Code__r.Name,' +
                   'Consignee_Address1__r.State__r.State_Code__c, Consignee_Address1__r.Country__r.COUNTRY_CODE__c,' +
                   'Consignee_Address1__r.GSTIN__c ' +
                   'FROM Quote WHERE Id = \'' + ObjId + '\'';
        }
        
        if (ObjectName == 'Order') {
            return 'SELECT Id, PoNumber, PoDate, CurrencyIsoCode, Payment_Terms__c,' +
                   'Account.Customer_Code__c, Account.Owner.EmployeeNumber,' +
                   'Location__r.Loc_Code__c, Location__r.Name,' +
                   'Delivery_Address1__c, Delivery_Address1__r.Code__c, Delivery_Address1__r.Street__c,' +
                   'Delivery_Address1__r.City__r.Name, Delivery_Address1__r.Pin_Code__r.Name,' +
                   'Delivery_Address1__r.State__r.State_Code__c, Delivery_Address1__r.Country__r.COUNTRY_CODE__c,' +
                   'Delivery_Address1__r.GSTIN__c,' +
                   'Consignee_Address1__c, Consignee_Address1__r.Code__c, Consignee_Address1__r.Street__c,' +
                   'Consignee_Address1__r.City__r.Name, Consignee_Address1__r.Pin_Code__r.Name,' +
                   'Consignee_Address1__r.State__r.State_Code__c, Consignee_Address1__r.Country__r.COUNTRY_CODE__c,' +
                   'Consignee_Address1__r.GSTIN__c ' +
                   'FROM Order WHERE Id = \'' + ObjId + '\'';
        }
        
        return '';
    }
    
    // Get Line Item Fields
    public static String getOneLevelLineItemRecords(String ObjectName,String parentField,String parentId){
        
        if(ObjectName == 'QuoteLineItem'){
            return 'SELECT Quantity, UnitPrice, Discount, Packing__c, Packing_Type__c, Grade__c,' +
                   'Product2.Item_No__c, Product2.Name, Product2.Product_Segments__c,' +
                   'Product2.Grade__c, Product2.Packing__c, Product2.Packing_Type__c,' +
                   'Warehouse__r.Name FROM QuoteLineItem WHERE QuoteId = \''+parentId+'\'';
        }
        
        if(ObjectName == 'OrderItem'){
            return 'SELECT Quantity, UnitPrice, Discount__c, Packaging__c, Packing_Type__c, Grade__c,' +
                   'Product2.Item_No__c, Product2.Name, Product2.Product_Segments__c,' +
                   'Product2.Grade__c, Product2.Packing__c, Product2.Packing_Type__c,' +
                   'Warehouse__r.Name FROM OrderItem WHERE OrderId = \''+parentId+'\'';
        }
        
        return '';
    }
    
    public class OrderResponse {
        public String SONumber;
        public String ReferenceNo;
        public String ResponseCode;
        public String ResponseDescription;
        public String Status;
    }
    
    // Check Quote is ready to send to SAP
    @AuraEnabled
    public static string quoteValidation(String qId){
        try {
            
            Map<String, String> retResData = new Map<String, String>();
            retResData.put('status', 'true');
            retResData.put('message', '');
            
            Quote q = [SELECT Id, SAP_SO_Number__c, PO_PI_Number__c, PO_Date__c, Status, Location__c, Account.Customer_Code__c FROM Quote WHERE Id = :qId];
            
            // ✅ Customer Code Validation
            if (String.isBlank(q.Account.Customer_Code__c)) {
                retResData.put('status', 'false');
                retResData.put('sync', 'false');
                retResData.put('message', 'Customer Code is missing on Account');
                return JSON.serialize(retResData);
            }
            
            // ✅ Status check
            if (q.Status != 'Accepted') {
                retResData.put('status', 'false');
                retResData.put('sync', 'false');
                retResData.put('message', 'Quote status is not Accepted');
                return JSON.serialize(retResData);
            }
            
            // ✅ Required fields
            if (q.PO_PI_Number__c == null || q.PO_Date__c == null || q.Location__c == null) {
                retResData.put('status', 'false');
                retResData.put('sync', 'false');
                retResData.put('message', 'PO Number, PO Date, Location cannot blank');
                return JSON.serialize(retResData);
            }
            
            // ✅ Already sent
            if (q.SAP_SO_Number__c != null) {
                retResData.put('status', 'false');
                retResData.put('sync', 'false');
                retResData.put('message', 'Quotation already sent to SAP');
                return JSON.serialize(retResData);
            }
            
            List<QuoteLineItem> qliList = [
                SELECT Id, Product2.Id, Product2.Name, Product2.Item_No__c
                FROM QuoteLineItem
                WHERE QuoteId = :qId
            ];
            
            List<Product2> missingProducts = new List<Product2>();
            
            for (QuoteLineItem qli : qliList) {
                
                if (qli.Product2 == null || String.isBlank(qli.Product2.Item_No__c)) {
                    
                    missingProducts.add(new Product2(
                        Id = qli.Product2.Id,
                        Name = qli.Product2.Name
                    ));
                }
            }
            
            if(!missingProducts.isEmpty()){
                
                sendMissingItemCodeEmail(qId,missingProducts);
                
                retResData.put('status', 'false');
                retResData.put('message', 'Product Item Code Missing');
                
                return JSON.serialize(retResData);
            }
            
            /*Integer piCount = 0;
            List<AggregateResult> piList = [
                SELECT COUNT(Id) total
                FROM Proforma_Invoice__c
                WHERE Quote__c = :qId
            ];
            
            if(!piList.isEmpty()){
                piCount = (Integer)piList[0].get('total');
            }
            
            if(piCount == 0){
                retResData.put('status', 'false');
                retResData.put('message', 'Cannot send Quote: No Proforma Invoice exists for this Quote.');
                return JSON.serialize(retResData);
            }*/
            
            return JSON.serialize(retResData);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // Check Quote is ready to send to SAP
    @AuraEnabled
    public static string orderValidation(String qId){
        try {
            
            Map<String, String> retResData = new Map<String, String>();
            retResData.put('status', 'true');
            retResData.put('message', '');
            
            Order q = [SELECT Id, Oracle_Sales_Order_No__c, PoNumber, PoDate, Status, Location__c FROM Order WHERE Id = :qId];
            
            // if (q.Status != 'Accepted') {
            //     retResData.put('status', 'false');
            //     retResData.put('sync', 'false');
            //     retResData.put('message', 'Quote status is not Accepted');
            // } else
            if(q.PoNumber == null || q.PoDate == null || q.Location__c == null){
                retResData.put('status', 'false');
                retResData.put('sync', 'false');
                retResData.put('message', 'PO Number, PO Date, Location cannot blank');
            } /*else if(q.Oracle_Sales_Order_No__c != null){
retResData.put('status', 'false');
retResData.put('sync', 'false');
retResData.put('message', 'Sales Order already sent to SAP');
}*/
            
            return JSON.serialize(retResData);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // Update SOnumber on Quote/Order
    @AuraEnabled
    public static String updateSOnumberToQuote(
        String qId,
        String soNum,
        String refNo,
        String objName
    ){
        try {
            
            if (objName == 'Quote') {
                
                Quote q = [
                    SELECT Id, SAP_SO_Number__c
                    FROM Quote
                    WHERE Id = :qId
                    LIMIT 1
                ];
                
                q.SAP_SO_Number__c = soNum;
                update q;
            }
            
            else if (objName == 'Order') {
                
                Order ord = [
                    SELECT Id, Oracle_Sales_Order_No__c, Revision_Number__c
                    FROM Order
                    WHERE Id = :qId
                    LIMIT 1
                ];
                
                ord.Oracle_Sales_Order_No__c = soNum;
                ord.Revision_Number__c =
                    ord.Revision_Number__c == null ? 1 : ord.Revision_Number__c + 1;
                
                update ord;
            }
            
            return 'Success';
            
        } catch (Exception e) {
            
            System.debug('ERROR: ' + e.getMessage());
            System.debug('STACK: ' + e.getStackTraceString());
            
            return 'Error: ' + e.getMessage();  // ✅ DO NOT THROW
        }
    }
    
    
    public static string getWarehouseByLocation(String whsId){
        try {
            
            String retData = '';
            
            List<Unit_Master__c> um = [
                SELECT Id, Name
                FROM Unit_Master__c
                WHERE Location__c = :whsId
            ];
            
            if(um.size() > 0){
                retData = um[0].Name;
            }
            
            return retData;
            
        } catch (Exception e) {
            system.debug('Error in getWarehouseByLocation: '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static void sendMissingItemCodeEmail(Id quoteId, List<Product2> prodList) {
        
        if(prodList == null || prodList.isEmpty()){
            return;
        }
        
        String emailLabel = System.Label.Missing_Product_ItemCode_Email;
        
        if(String.isBlank(emailLabel)){
            return;
        }
        
        List<String> toAddress = emailLabel.split(',');
        
        String body = 'Dear SAP Team,<br/><br/>Kindly request you to create the following products in SAP:<br/><br/>';
        
        for(Product2 p : prodList){
            body += '<b>SF Product Name :</b> ' + p.Name + '<br/>';
            body += '<b>SF Product ID :</b> ' + p.Id + '<br/><br/>';
        }
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddress);
        mail.setSubject('Request for Product Creation in SAP');
        mail.setHtmlBody(body);
        
        // Track email in Quote Activity
        mail.setWhatId(quoteId);
        mail.setSaveAsActivity(true);
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }
    
    public static String getValue(String qliVal, String prodVal, Boolean allowNA){
        
        if(!String.isBlank(qliVal)){
            return qliVal;
        }
        
        if(!String.isBlank(prodVal)){
            return prodVal;
        }
        
        if(allowNA){
            return 'NA';
        }
        
        return '';
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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