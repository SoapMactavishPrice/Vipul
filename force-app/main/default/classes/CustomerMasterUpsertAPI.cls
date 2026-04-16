@RestResource(urlMapping = '/CustomerMasterUpsert')
global class CustomerMasterUpsertAPI {
    @HttpPost
    global static void doPost() {
        
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String jSONRequestBody = request.requestBody.toString().replace('\n', '');
        
        // ------------------- API LOG to track the request -------------------
        API_Log__c api_log = new API_Log__c();
        api_log.API_log_Name__c = 'CustomerMasterUpsert_API';
        api_log.Request__c = jSONRequestBody;
        api_log.Request_Created_Time__c = Datetime.now();
        
        List < JSON2ApexSaveWebToLead > jsonDataAccountList = JSON2ApexSaveWebToLead.parse(jSONRequestBody);
        System.debug('======----->jsonDataAccountList' + jsonDataAccountList);
        
        try {
            
            Map < String, Object > responseMap = new Map < String, Object > ();
            Map < String, String > existingHSNCodeMap = new Map < String, String > ();
            
            List < Account > upsertAccountList = new List < Account > ();
            
            // Get Existing Accounts list
            List < Account > existingAccountList = [
                SELECT Id, Name, Customer_Code__c
                FROM Account
                WHERE Customer_Code__c != null
            ];
            
            Set<String> customerCodeSet = new Set<String>();
            Set<Id> sfIdSet = new Set<Id>();
            
            for (JSON2ApexSaveWebToLead obj : jsonDataAccountList) {
                if (!String.isBlank(obj.customerCode)) {
                    customerCodeSet.add(obj.customerCode);
                }
                if (!String.isBlank(obj.sfbpcode)) {
                    try {
                        sfIdSet.add((Id)obj.sfbpcode);
                    } catch (Exception e) {
                        System.debug('Invalid SF Id: ' + obj.sfbpcode);
                    }
                }
            }
            
            Map<Id, Account> accById = new Map<Id, Account>();
            Map<String, Account> accByCustomerCode = new Map<String, Account>();
            
            for (Account acc : [
                SELECT Id, Customer_Code__c
                FROM Account
                WHERE Id IN :sfIdSet
                OR Customer_Code__c IN :customerCodeSet
            ]) {
                accById.put(acc.Id, acc);
                
                if (acc.Customer_Code__c != null) {
                    accByCustomerCode.put(acc.Customer_Code__c, acc);
                }
            }
                        
            // Raed List of JSON data
            for (JSON2ApexSaveWebToLead jsonObj: jsonDataAccountList) {
                Account p;
                
                // 🔥 PRIORITY 1 → SF Id
                if (!String.isBlank(jsonObj.sfbpcode) && accById.containsKey((Id)jsonObj.sfbpcode)) {
                    p = accById.get((Id)jsonObj.sfbpcode);
                }
                // 🔥 PRIORITY 2 → Customer Code
                else if (!String.isBlank(jsonObj.customerCode) && accByCustomerCode.containsKey(jsonObj.customerCode)) {
                    p = accByCustomerCode.get(jsonObj.customerCode);
                }
                // 🔥 INSERT
                else {
                    p = new Account();
                }
                
                if (!String.isBlank(jsonObj.customerCode)) {
                    p.Customer_Code__c = jsonObj.customerCode;
                    
                    if (!String.isBlank(jsonObj.customerName)) {
                        p.Name = jsonObj.customerName;
                    }
                    if (!String.isBlank(jsonObj.bpType)) {
                        p.Business_Partner_Type__c = jsonObj.bpType;
                    }
                   if (!String.isBlank(jsonObj.customerGroup)) {
                        p.Customer_Type__c = jsonObj.customerGroup;
                    }
                /*    if (!String.isBlank(jsonObj.customerType)) {
                        p.Customer_Type__c = jsonObj.customerType;
                    } */
              
                    
                    if (!String.isBlank(jsonObj.phone)) {
                        p.Phone = jsonObj.phone;
                    }
                    if (!String.isBlank(jsonObj.bpCurrency)) {
                        if (jsonObj.bpCurrency == '##'){
                            p.CurrencyIsoCode = 'USD'; 
                        }else{
                            p.CurrencyIsoCode = jsonObj.bpCurrency;
                        }
                    }
                    if (!String.isBlank(jsonObj.creditLimit)) {
                        p.Credit_Limit__c = Decimal.valueOf(jsonObj.creditLimit);
                    }
                    if (!String.isBlank(jsonObj.territory)) {
                        p.Territory__c = jsonObj.territory;
                    }
                    if (!String.isBlank(jsonObj.mobile)) {
                        p.Landline_Number_1__c = jsonObj.mobile;
                    }
                    if (!String.isBlank(jsonObj.active)) {
                        p.Active__c = Boolean.valueOf(jsonObj.active);
                    }
                    if (!String.isBlank(jsonObj.salesEmployeeName)) {
                        p.Sales_Employee_Name__c = jsonObj.salesEmployeeName;
                    }
                    if (!String.isBlank(jsonObj.salesEmployee)) {
                        p.Sales_Employee_Code__c = jsonObj.salesEmployee;
                    }
                    if (!String.isBlank(jsonObj.ownerName)) {
                        p.Owner_Name__c = jsonObj.ownerName;
                    }
                    if (!String.isBlank(jsonObj.paymentTerms)) {
                        p.Payment_Terms__c = jsonObj.paymentTerms;
                    }
                    if (!String.isBlank(jsonObj.ownerCode)) {
                        p.Owner_Code__c = jsonObj.ownerCode;
                        List<User> usr1 = [SELECT Id, Name, EmployeeNumber FROM User WHERE EmployeeNumber = :jsonObj.ownerCode];
                        if (usr1.size() > 0) {
                            p.OwnerId = usr1[0].Id;
                        }
                    }
                    upsertAccountList.add(p);
                } else {
                    throw new IllegalArgumentException('customerCode required');
                }
            }
            
            if (upsertAccountList.size() > 0) {
                upsert upsertAccountList;
            }
            
            Map<String, String> custCodeCustIdMap = new Map<String, String>();
            Set<String> customerIdSet = new Set<String>();
            
            for (Account acc : upsertAccountList) {
                custCodeCustIdMap.put(acc.Customer_Code__c, acc.Id);
                customerIdSet.add(acc.Id);
            }
            System.debug(customerIdSet);
            
            // Upsert Address Information
            List<Address_Information__c> upsertAddInfoList = new List<Address_Information__c>();
            
            // 🔹 NEW: Collect State & Country
            Set<String> stateSet = new Set<String>();
            Set<String> countrySet = new Set<String>();

            for (JSON2ApexSaveWebToLead obj : jsonDataAccountList) {
                if (obj.address != null) {
                    for (AddInfoWrapper var : obj.address) {
                        if (!String.isBlank(var.state)) stateSet.add(var.state.trim());
                        if (!String.isBlank(var.country)) countrySet.add(var.country.trim());
                    }
                }
            }

            // 🔹 Query existing
            Map<String, Id> stateMap = new Map<String, Id>();
            for (State__c s : [SELECT Id, Name FROM State__c WHERE Name IN :stateSet]) {
                stateMap.put(s.Name, s.Id);
            }

            Map<String, Id> countryMap = new Map<String, Id>();
            for (Country__c c : [SELECT Id, Name FROM Country__c WHERE Name IN :countrySet]) {
                countryMap.put(c.Name, c.Id);
            }

            // 🔹 Create missing States
            List<State__c> newStates = new List<State__c>();
            for (String s : stateSet) {
                if (!stateMap.containsKey(s)) {
                    newStates.add(new State__c(Name = s));
                }
            }
            if (!newStates.isEmpty()) {
                insert newStates;
                for (State__c s : newStates) {
                    stateMap.put(s.Name, s.Id);
                }
            }

            // 🔹 Create missing Countries
            List<Country__c> newCountries = new List<Country__c>();
            for (String c : countrySet) {
                if (!countryMap.containsKey(c)) {
                    newCountries.add(new Country__c(Name = c));
                }
            }
            if (!newCountries.isEmpty()) {
                insert newCountries;
                for (Country__c c : newCountries) {
                    countryMap.put(c.Name, c.Id);
                }
            }
            
            
            List<Address_Information__c> exAddInfoList = [
                SELECT Id, Name, Code__c, RecordType.DeveloperName
                FROM Address_Information__c
                WHERE Account__c IN :customerIdSet
            ];
            
            Map<String, String> addCodeAddIdMap = new Map<String, String>();
            for (Address_Information__c adi : exAddInfoList) {
                String tLabel = '';
                if (adi.RecordType.DeveloperName == 'Bill_To') {
                    tLabel = 'B';
                } else if (adi.RecordType.DeveloperName == 'Ship_To') {
                    tLabel = 'S';
                }
                addCodeAddIdMap.put(adi.Code__c+tLabel, adi.Id);
            }
            
            List<RecordType> addRecTypeList = [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Address_Information__c'];
            Map<String, String> recTypeIdMap = new Map<String, String>();
            for (RecordType rt : addRecTypeList) {
                recTypeIdMap.put(rt.DeveloperName, rt.Id);
            }
            
            for (JSON2ApexSaveWebToLead obj : jsonDataAccountList) {
                if (obj.address != null && obj.address.size() > 0) {
                    for (AddInfoWrapper var : obj.address) {
                        if (!String.isBlank(var.addressType) && !String.isBlank(var.addressCode)) {
                            Address_Information__c addInfo = new Address_Information__c();
                            if (addCodeAddIdMap.containsKey(var.addressCode+var.addressType)) {
                                addInfo.Id = addCodeAddIdMap.get(var.addressCode+var.addressType);
                            } else {
                                if (var.addressType == 'B') {
                                    addInfo.RecordTypeId = recTypeIdMap.get('Bill_To');
                                } else if (var.addressType == 'S') {
                                    addInfo.RecordTypeId = recTypeIdMap.get('Ship_To');
                                }
                                addInfo.Account__c = custCodeCustIdMap.get(obj.customerCode);
                            }
                            addInfo.Code__c = var.addressCode;
                            addInfo.Street__c = var.street;
                            addInfo.Block__c = var.Block;
                            
                            if (!String.isBlank(var.state)) {
                                addInfo.State__c = stateMap.get(var.state.trim());
                            }
                            
                            if (!String.isBlank(var.country)) {
                                addInfo.Country__c = countryMap.get(var.country.trim());
                            }
                            
                            if (!String.isBlank(var.primaryAddress)) {
                                addInfo.Primary_Address__c = Boolean.valueOf(var.primaryAddress);
                            }
                            if (!String.isBlank(var.city)) {
                                List<City__c> pc = [SELECT Id, Name FROM City__c WHERE Name = :var.city];
                                if (pc.size() > 0) {
                                    addInfo.City__c = pc[0].Id;
                                }
                            }
                            if (!String.isBlank(var.postalCode)) {
                                List<Pin_Code__c> pc = [SELECT Id, Name FROM Pin_Code__c WHERE Name = :var.postalCode];
                                if (pc.size() > 0) {
                                    addInfo.Pin_Code__c = pc[0].Id;
                                }
                            }
                            /*if (!String.isBlank(var.state)) {
                                List<State__c> pc = [SELECT Id, Name FROM State__c WHERE Name = :var.state];
                                if (pc.size() > 0) {
                                    addInfo.State__c = pc[0].Id;
                                }
                            }
                            if (!String.isBlank(var.country)) {
                                List<Country__c> pc = [SELECT Id, Name FROM Country__c WHERE Name = :var.country];
                                if (pc.size() > 0) {
                                    addInfo.Country__c = pc[0].Id;
                                }
                            }*/
                            upsertAddInfoList.add(addInfo);
                        } else {
                            throw new IllegalArgumentException('addressType and addressCode cannot be blank');
                        }
                    }
                }
            }
            System.debug(upsertAddInfoList);
            
            if (upsertAddInfoList.size() > 0) {
                upsert upsertAddInfoList;
            }
            
            // Upsert Contact
            List<Contact> upsertContactList = new List<Contact>();
            List<Contact> exContactList = [
                SELECT Id, Name, Contact_Code__c, Email
                FROM Contact
                WHERE AccountId IN :customerIdSet
            ];
            
            Map<String, String> conCodeConIdMap = new Map<String, String>();
            for (Contact co : exContactList) {
                conCodeConIdMap.put(co.Email, co.Id);
            }
            
            for (JSON2ApexSaveWebToLead obj : jsonDataAccountList) {
                if (obj.contactInfo != null && obj.contactInfo.size() > 0) {
                    for (ContInfoWrapper var : obj.contactInfo) {
                        if (!String.isBlank(var.lastName) && !String.isBlank(var.email)) {
                            Contact addnewContact = new Contact();
                            if (conCodeConIdMap.containsKey(var.email)) {
                                addnewContact.Id = conCodeConIdMap.get(var.email);
                            } else {
                                addnewContact.AccountId = custCodeCustIdMap.get(obj.customerCode);
                            }
                            addnewContact.FirstName = var.firstName;
                            addnewContact.LastName = var.lastName;
                            addnewContact.Job_Title_Designation__c = var.position;
                            addnewContact.Phone = var.contactPhone;
                            addnewContact.MobilePhone = var.mobilePhone;
                            addnewContact.Email = var.email;
                            upsertContactList.add(addnewContact);
                        } else {
                            throw new IllegalArgumentException('lastName and email cannot be blank');
                        }
                    }
                }
            }
            
            if (upsertContactList.size() > 0) {
                upsert upsertContactList;
            }
            
            // Create Response
            
            Set<String> customerIdSet_temp = new Set<String>();
            for (Account acc : upsertAccountList) {
                customerIdSet_temp.add(acc.Id);
            }
            List<Address_Information__c> exAddInfoList_temp = [
                SELECT Id, Name, Code__c, RecordType.DeveloperName, RecordTypeId, Account__c
                FROM Address_Information__c
                WHERE Account__c IN :customerIdSet_temp
            ];
            
            Set<String> contactIdSet_temp = new Set<String>();
            for (Contact con : upsertContactList) {
                contactIdSet_temp.add(con.Id);
            }
            List<Contact> excontInfoList_temp = [
                SELECT Id, Name, AccountId, FirstName, LastName, Email
                FROM Contact
                WHERE Id IN :contactIdSet_temp
            ];
            
            List<Map<String, Object>> accMapList = new List<Map<String, Object>>();
            for (Account acc : upsertAccountList) {
                System.debug(acc);
                Map<String, Object> accMap = new Map<String, Object>();
                List<Map<String, Object>> addMapList = new List<Map<String, Object>>();
                accMap.put('customerCode', acc.Customer_Code__c);
                accMap.put('customerName', acc.Name);
                accMap.put('SFID', acc.Id);
                for (Address_Information__c add : exAddInfoList_temp) {
                    if (add.Account__c == acc.Id) {
                        Map<String, Object> addMap = new Map<String, Object>();
                        if (add.RecordType.DeveloperName == 'Bill_To') {
                            addMap.put('addressType', 'B');
                        } else if (add.RecordType.DeveloperName == 'Ship_To') {
                            addMap.put('addressType', 'S');
                        }
                        addMap.put('addressCode', add.Code__c);
                        addMap.put('SFID', add.Id);
                        addMapList.add(addMap);
                    }
                }
                accMap.put('addressList', addMapList);
                
                List<Map<String, Object>> contMapList = new List<Map<String, Object>>();
                for (Contact c : excontInfoList_temp) {
                    System.debug(c);
                    if (c.AccountId == acc.Id) {
                        Map<String, Object> conMap = new Map<String, Object>();
                        conMap.put('firstName', c.FirstName);
                        conMap.put('lastName', c.LastName);
                        conMap.put('email', c.Email);
                        conMap.put('SFID', c.Id);
                        contMapList.add(conMap);
                    }
                }
                accMap.put('contactInfo', contMapList);
                accMapList.add(accMap);
            }
            
            responseMap.put('customer', accMapList);
            responseMap.put('status', 'success');
            responseMap.put('message', 'Inserted/Updated Successfully');
            
            String resp = JSON.serialize(responseMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 200;
            
            api_log.Status__c = 'Success';
            api_log.Response_Code__c = '200';
            api_log.Response__c = String.valueOf(resp);
            api_log.response_time__c = Datetime.now();
            
        } catch (Exception e) {
            System.debug('Catch Error' + e.getStackTraceString());
            System.debug('Catch Error' + e.getMessage());
            System.debug('Catch Error' + e.getlineNumber());
            
            // ------------------- Create Response Map -------------------
            Map < string, string > errorResMap = new Map < string, string > ();
            // errorResMap.put('Message', 'Something went wrong');
            // errorResMap.put('Error1', e.getMessage());
            // errorResMap.put('Error2', '' + e.getlineNumber());
            // errorResMap.put('Error3', '' + String.valueOf(e));
            
            errorResMap.put('status', 'fail');
            errorResMap.put('message', e.getMessage());
            
            // ------------------- Send Response Map -------------------
            String resp = JSON.serialize(errorResMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 400;
            
            api_log.Status__c = 'Failure';
            api_log.Response_Code__c = '400';
            api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            api_log.response_time__c = Datetime.now();
            
        }
        
        insert api_log;
    }
    
    public class JSON2ApexSaveWebToLead {
        public String mobile;
        public String active;
        public String salesEmployeeName;
        public String salesEmployee;
        public String ownerName;
        public String paymentTerms;
        public String ownerCode;
        public String customerCode;
        public String sfbpcode;
        public String customerName;
        public String bpType;
        public String customerGroup;
        public String customerType;
        public String phone;
        public String bpCurrency;
        public String creditLimit;
        public String territory;
        public List<AddInfoWrapper> address;
        public List<ContInfoWrapper> contactInfo;
    }
    
    public class AddInfoWrapper {
        public String primaryAddress;
        public String addressType;
        public String street;
        public String city;
        public String postalCode;
        public String state;
        public String country;
        public String addressCode;
        public String Block;
    }
    
    public class ContInfoWrapper {
        public String contactCode;
        public String firstName;
        public String lastName;
        public String position;
        public String contactPhone;
        public String mobilePhone;
        public String email;
    }
    
    
    public static List < JSON2ApexSaveWebToLead > parse(String json) {
        return (List < JSON2ApexSaveWebToLead > ) System.JSON.deserialize(json, List < JSON2ApexSaveWebToLead > .class);
    }
    
    public static String getPicklistValueFromLabel(String objectName, String fieldName, String labelValue) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectType = globalDescribe.get(objectName);
        Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
        Schema.DescribeFieldResult fieldResult = describeResult.fields.getMap().get(fieldName).getDescribe();
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.getLabel() == labelValue) {
                return entry.getValue(); // API Name
            }
        }
        return null;
}
    
}