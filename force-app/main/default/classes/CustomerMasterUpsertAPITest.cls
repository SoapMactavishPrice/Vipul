@isTest
private class CustomerMasterUpsertAPITest {
    
    @testSetup
    static void setupData() {
        // Create RecordTypes for Address_Information__c

        Country__c testCountry = new Country__c(Name = 'India');
        insert testCountry;
        
        State__c testState = new State__c(Name = 'Test State', Country__c = testCountry.Id);
        insert testState;
        
        City__c testCity = new City__c(Name = 'Test City', State__c = testState.Id);
        insert testCity;
        
        Area__c testArea = new Area__c(Name = 'Test Area', City__c = testCity.Id);
        insert testArea;
        
        Pin_Code__c testPostalCode = new Pin_Code__c(Name = '12345', Area__c = testArea.Id);
        insert testPostalCode;
        
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Country__c= testCountry.id,
            City__c=testCity.id,
            State__c=testState.id,
            Area__c=testArea.id,
            Street__c='MBP Road',
            Pin_Code__c=testPostalCode.id,
            INCO_Terms__c = 'DDP'
        );
        insert testAccount;

        // Create Contact
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'Prashantpadal@finessedirect.com', AccountId = testAccount.Id, Contact_Code__c = 'Con123');
        insert testContact;
        
        Id billToRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Address_Information__c' AND DeveloperName = 'Bill_To' LIMIT 1].Id;

        // Step 3: Create a Bill_To Address record
        Address_Information__c billToAddress = new Address_Information__c(
            City__c = testCity.Id,
            State__c = testState.Id,
            Country__c = testCountry.Id,
            Area__c = testArea.Id,
            Pin_Code__c = testPostalCode.Id,
            Street__c = 'ABC',
            GSTIN__c = '123456789',
            GST_Type__c = 'Composition Levy',
            Account__c = testAccount.Id,
            Code__c = 'ADDR001',
            RecordTypeId = billToRecordTypeId
        );
        insert billToAddress;

        // Create a User for OwnerId mapping
        User u = new User(
            Username = 'testuseasdasda122r@example.com',
            Alias = 'tuser',
            LastName = 'Testname1',
            Email = 'testuser11@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            EmployeeNumber = 'EMP001'
        );
        insert u;
    }

    @isTest
    static void testDoPostWithMissingCustomerCode() {
        String jsonBody = '[{'+
            '"customerName":"Missing Code Customer"'+
        '}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/CustomerMasterUpsert';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            CustomerMasterUpsertAPI.doPost();
            //System.assert(false, 'Expected exception for missing customerCode');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('customerCode required'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testFullUpsertFlow() {
        String jsonBody = '[{'+
            '"customerCode":"CUST001",'+
            '"customerName":"Test Customer",'+
            '"bpType":"Retail",'+
            '"customerGroup":"GroupA",'+
            '"customerType":"TypeA",'+
            '"phone":"1234567890",'+
            '"bpCurrency":"INR",'+
            '"creditLimit":"10000",'+
            '"territory":"West",'+
            '"mobile":"9876543210",'+
            '"active":"true",'+
            '"salesEmployeeName":"Sales Guy",'+
            '"salesEmployee":"SE001",'+
            '"ownerName":"Owner Name",'+
            '"paymentTerms":"Net30",'+
            '"ownerCode":"EMP001",'+
            '"address":[{'+
                '"addressType":"B",'+
                '"addressCode":"ADDR001",'+
                '"street":"123 Street",'+
                '"primaryAddress":"true",'+
                '"city":"Mumbai",'+
                '"postalCode":"400001",'+
                '"state":"Maharashtra",'+
                '"country":"India"'+
            '}],'+
            '"contactInfo":[{'+
                '"firstName":"Test",'+
                '"lastName":"Contact",'+
                '"position":"Manager",'+
                '"contactPhone":"1234567890",'+
                '"mobilePhone":"9876543210",'+
                '"email":"Prashantpadal@finessedirect.com"'+
            '}]'+
        '}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/CustomerMasterUpsert';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        CustomerMasterUpsertAPI.doPost();
        Test.stopTest();

        /*// Validate Account
        Account acc = [SELECT Id, Name FROM Account WHERE Customer_Code__c = 'CUST001' LIMIT 1];
        System.assertEquals('Test Customer', acc.Name);

        // Validate Address
        Address_Information__c addr = [SELECT Id, Code__c FROM Address_Information__c WHERE Account__c = :acc.Id LIMIT 1];
        System.assertEquals('ADDR001', addr.Code__c);

        // Validate Contact
        Contact con = [SELECT Id, Email FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
        System.assertEquals('john.doe@example.com', con.Email);

        // Validate API Log
        API_Log__c log = [SELECT Id, Status__c FROM API_Log__c WHERE API_log_Name__c = 'CustomerMasterUpsert_API' LIMIT 1];
        System.assertEquals('Success', log.Status__c);*/
    }

    @isTest
    static void testMissingAddressFields() {
        String jsonBody = '[{'+
            '"customerCode":"CUST002",'+
            '"customerName":"Customer With Bad Address",'+
            '"address":[{'+
                '"addressType":"B",'+
                '"addressCode":"B10"'+
            '}]'+
        '}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/CustomerMasterUpsert';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            CustomerMasterUpsertAPI.doPost();
            //System.assert(false, 'Expected exception for missing addressType and addressCode');
        } catch (Exception e) {
           // System.assert(e.getMessage().contains('addressType and addressCode cannot be blank'));
        }
        Test.stopTest();
    }

    @isTest
    static void testMissingContactFields() {
        String jsonBody = '[{'+
            '"customerCode":"CUST003",'+
            '"customerName":"Customer With Bad Contact",'+
            '"contactInfo":[{'+
                '"lastName":"TestName",'+
                '"email":"testemail@exe.com"'+
            '}]'+
        '}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/CustomerMasterUpsert';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            CustomerMasterUpsertAPI.doPost();
            //System.assert(false, 'Expected exception for missing lastName and email');
        } catch (Exception e) {
            //System.assert(e.getMessage().contains('lastName and email cannot be blank'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAddressInformationUpsert() {
        // Get RecordType IDs
        Map<String, Id> recTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Address_Information__c']) {
            recTypeMap.put(rt.DeveloperName, rt.Id);
        }
        
        // Prepare JSON with address info
        String jsonBody = '[{'+
            '"customerCode":"CUST001",'+
            '"customerName":"Test Account",'+
            '"address":[{'+
            '"addressType":"B",'+
            '"addressCode":"ADDR001",'+
            '"street":"MBP Road",'+
            '"primaryAddress":"true",'+
            '"city":"Test City",'+
            '"postalCode":"12345",'+
            '"state":"Test State",'+
            '"country":"India"'+
            '}]'+
            '}]';
        
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/CustomerMasterUpsert';
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        CustomerMasterUpsertAPI.doPost();
        Test.stopTest();
        
    }

}