public class CustomerUpsertToSAP {

    @AuraEnabled
    public static string customerValidation(String accId){
        try {

            Account acc = [
                SELECT Id, Payment_Terms__c, Sales_Employee_Code__c, Card_Type__c, Credit_Limit__c, Business_Partner_Type__c,
                Customer_Group__c, Customer_Type__c,PAN_No__c, CurrencyIsoCode
                FROM account
                WHERE Id = :accId
            ];


            // if(String.isBlank(acc.Sales_Employee_Code__c)){
            //     return 'Sales_Employee_Code__c Missing';
            // }

            // if(String.isBlank(acc.Payment_Terms__c)){
            //     return 'Payment_Terms__c Missing';
            // }

            // if(String.isBlank(acc.Card_Type__c)){
            //     return 'Card_Type__c Missing';
            // }

            if(acc.Credit_Limit__c == null){
                return 'Credit Limit cannot be blank!';
            }

            if(acc.CurrencyIsoCode == 'INR' && String.isBlank(acc.PAN_No__c)){
                return 'PAN cannot be blank when currency is INR!';
            }

            /*if(acc.Customer_Group__c == null){
                return 'Customer Group cannot be blank!';
            }*/

            if(acc.Customer_Type__c == null){
                return 'Customer Type cannot be blank!';
            }

            // List<Address_Information__c> billToList = [
            //     SELECT Id, RecordTypeId, Primary_Address__c, City__c, Pin_Code__c, State__c, Country__c, RecordType.DeveloperName,
            //     Street__c, City__r.Name, Pin_Code__r.Name, State__r.State_Code__c, Country__r.COUNTRY_CODE__c, Account__r.Name
            //     FROM Address_Information__c
            //     WHERE Account__c =: accId
            //     AND RecordType.DeveloperName = 'Bill_To'
            // ];

            // if (billToList.size() == 0) {
            //     return 'Bill To address cannot be blank!';
            // }

            List<Address_Information__c> shipToList = [
                SELECT Id, RecordTypeId, Primary_Address__c, City__c, Pin_Code__c, State__c, Country__c, RecordType.DeveloperName,
                Street__c, City__r.Name, Pin_Code__r.Name, State__r.State_Code__c, Country__r.COUNTRY_CODE__c, Account__r.Name, Block__c
                FROM Address_Information__c
                WHERE Account__c =: accId
                AND RecordType.DeveloperName = 'Ship_To'
            ];

            if (shipToList.size() == 0) {
                return 'Ship To address cannot be blank!';
            }
            
            List<Contact> getContactList = [
                SELECT Id, FirstName, LastName, Job_Title_Designation__c, Phone, MobilePhone, Email
                FROM Contact
                WHERE AccountId =: accId
            ];
                
            if (getContactList.size() == 0) {
                return 'Atleast One contact person is required!';
            }

             // Add Address Validation


            return 'ok';
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String sendCustomerData(String accId) {

        String responseBodyData = '';

        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.API_log_Name__c = 'CustomerUpsert_ToSAP';
        api_log.Request_Created_Time__c = DateTime.now();

        try {

            String jsonBody = createJSONrequest(accId);
            api_log.Request__c = jsonBody;

            // Define API URL
            String apiUrl = label.CreateCustomerOracle;

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
            List<OrderResponse> responseList = (List<OrderResponse>) JSON.deserialize(responseBody, List<OrderResponse>.class);
            // responseBodyData = parseresponseBodyData(responseBody, soId);
            responseBodyData = responseBody;

            if(res.getStatusCode() == 200) {
                api_log.Status__c = 'Success';
            } else {
                api_log.Status__c = 'Failure';
            }

            api_log.Response_Code__c = String.valueOf(res.getStatusCode());
            api_log.Response__c = res.getBody();
            api_log.response_time__c = Datetime.now();

        } catch (Exception e) {
            System.debug('Error in API Call: ' + e.getMessage());
            responseBodyData = e.getMessage();
            api_log.Status__c = 'Failure';
            api_log.Response_Code__c = '400';
            api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            api_log.response_time__c = Datetime.now();
        }

        api_log.Account__c = accId;
        insert api_log;

        return responseBodyData;

    }

    public static String createJSONrequest(String Id){

        Account acc = [
            SELECT Id, Name, Business_Partner_Type__c, Customer_Group__c, Customer_Type__c,PAN_No__c,
            CurrencyIsoCode, Credit_Limit__c, Territory__c, Phone, Landline_Number_1__c,Card_Type__c,
            Active__c, Sales_Employee_Name__c, Sales_Employee_Code__c, Owner_Name__c, Payment_Terms__c, Owner_Code__c,
            Owner.Name, Owner.EmployeeNumber, Block__c
            FROM Account
            // WHERE Id = '001Hz00000tPgzQIAS'
            WHERE Id =: Id
        ];

        List<Address_Information__c> getAddList = [
            SELECT Id, RecordTypeId, Primary_Address__c, City__c, Pin_Code__c, State__c, Country__c, RecordType.DeveloperName,
            Street__c, City__r.Name, Pin_Code__r.Name, State__r.State_Code__c, Country__r.COUNTRY_CODE__c, Account__r.Name, Block__c
            FROM Address_Information__c
            WHERE Account__c =: Id
        ];

        List<Contact> getContactList = [
            SELECT Id, FirstName, LastName, Job_Title_Designation__c, Phone, MobilePhone, Email
            FROM Contact
            WHERE AccountId =: Id
        ];
        
        String customerTypeAPI = acc.Customer_Type__c;
        String customerTypeLabel = getPicklistLabel(Account.Customer_Type__c, customerTypeAPI);


        List<Map<String, Object>> mainMap = new List<Map<String, Object>>();
        Map<String, Object> primaryMap = new Map<String, Object>();
        List<Map<String, Object>> listAddressMap = new List<Map<String, Object>>();
        List<Map<String, Object>> listContactMap = new List<Map<String, Object>>();

        primaryMap.put('customerName',acc.Name == null ? '' : acc.Name);
        // primaryMap.put('bpType',acc.Business_Partner_Type__c == null ? '' : acc.Business_Partner_Type__c);
        primaryMap.put('bpType', '');
        primaryMap.put('customerGroup', customerTypeAPI);
        primaryMap.put('customerType', customerTypeLabel);
        primaryMap.put('phone',acc.Phone == null ? '' : acc.Phone);
        primaryMap.put('bpCurrency',acc.CurrencyIsoCode == null ? '' : acc.CurrencyIsoCode);
        primaryMap.put('creditLimit', acc.Credit_Limit__c);
        primaryMap.put('territory',acc.Territory__c == null ? '' : acc.Territory__c);
        primaryMap.put('mobile',acc.Landline_Number_1__c == null ? '' : acc.Landline_Number_1__c);
        // primaryMap.put('active', acc.Active__c ? 'Y' : 'N');
        primaryMap.put('active', 'Y');
        primaryMap.put('salesEmployeeName','');
        primaryMap.put('salesEmployee','-1');
        primaryMap.put('ownerName', acc.Owner != null && acc.Owner.Name != null ? acc.Owner.Name : '');
        
        // primaryMap.put('paymentTerms',acc.Payment_Terms__c == null ? '' : acc.Payment_Terms__c);
        primaryMap.put('paymentTerms', '1');
        primaryMap.put('U_SFCardCode', acc.Id);
        primaryMap.put('CardCode', '');
        primaryMap.put('Series', '86'); // Need to check
        primaryMap.put('OwnerCode', acc.Owner != null && acc.Owner.EmployeeNumber != null ? acc.Owner.EmployeeNumber : '');
        
        // primaryMap.put('OwnerCode', '132'); // For production
        primaryMap.put('CardType', acc.Card_Type__c != null ? acc.Card_Type__c : 'C'); // Need to check
        primaryMap.put('PANNumber', acc.PAN_No__c); // Need to check
        primaryMap.put('block', acc.Block__c == null ? '' : acc.Block__c);

        for(Address_Information__c addInfo : getAddList){
            Map<String, Object> addressMap = new Map<String, Object>();
            addressMap.put('SFID', addInfo.Id);
            addressMap.put('primaryAddress', acc.Name);
            addressMap.put('AddressName', acc.Name);
            addressMap.put('street', addInfo.Street__c);
            addressMap.put('block', addInfo.Block__c == null ? '' : addInfo.Block__c);
            if (addInfo.RecordType.DeveloperName == 'Bill_To') {
                addressMap.put('addressType', 'B');
            } else if (addInfo.RecordType.DeveloperName == 'Ship_To') {
                addressMap.put('addressType', 'S');
            }
            if (addInfo.City__c != null) {
                addressMap.put('city', addInfo.City__r.Name);
            }
            if (addInfo.Pin_Code__c != null) {
                addressMap.put('postalCode', addInfo.Pin_Code__r.Name);
            }
            if (addInfo.State__c != null) {
                addressMap.put('state', addInfo.State__r.State_Code__c);
            }
            if (addInfo.Country__c != null) {
                addressMap.put('country', addInfo.Country__r.COUNTRY_CODE__c);
            }
            listAddressMap.add(addressMap);
        }
        primaryMap.put('address', listAddressMap);

        for(Contact con : getContactList){
            Map<String, Object> contactMap = new Map<String, Object>();
            contactMap.put('firstName', con.FirstName);
            contactMap.put('lastName', con.LastName);
            contactMap.put('position', con.Job_Title_Designation__c);
            contactMap.put('contactPhone', con.Phone);
            contactMap.put('mobilePhone', con.MobilePhone);
            contactMap.put('email', con.Email);
            listContactMap.add(contactMap);
        }
        primaryMap.put('contactInfo', listContactMap);

        mainMap.add(primaryMap);
        return json.serialize(mainMap);

    }
    
    public static String getPicklistLabel(Schema.SObjectField field, String value){
        if(String.isBlank(value)) return '';
        
        for(Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()){
            if(entry.getValue() == value){
                return entry.getLabel();
            }
        }
        return '';
    }

    @AuraEnabled
    public static string updateCustomerData(String custNumber, String cId){
        try {

            Account acc = [
                SELECT Id, Name, Customer_Code__c
                FROM Account
                WHERE Id = :cId
            ];

            acc.Customer_Code__c = custNumber;
            update acc;

            List<Address_Information__c> getAddList = [
                SELECT Id, RecordTypeId, Primary_Address__c, City__c, Pin_Code__c, State__c, Country__c, RecordType.DeveloperName,
                Street__c, City__r.Name, Pin_Code__r.Name, State__r.State_Code__c, Country__r.COUNTRY_CODE__c, Account__r.Name
                FROM Address_Information__c
                WHERE Account__c =: cId
                AND Sync_to_SAP__c = false
            ];

            for (Address_Information__c add : getAddList) {
                add.Sync_to_SAP__c = true;
            }

            if (getAddList.size() > 0) {
                update getAddList;
            }

            return 'ok';
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class OrderResponse {
        public String ReferenceNo;
        public String ResponseCode;
        public String ResponseDescription;
        public String Status;
        public String SFBPCode;
        public String CardCode;
    }

}