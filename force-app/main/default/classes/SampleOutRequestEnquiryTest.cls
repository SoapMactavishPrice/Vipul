@IsTest
private class SampleOutRequestEnquiryTest {
    
    @TestSetup
    static void setupTestData() {
        Country__c testCountry = new Country__c(Name = 'Test Country');
        insert testCountry;
        
        State__c testState = new State__c(Name = 'Test State', Country__c = testCountry.Id);
        insert testState;
        
        City__c testCity = new City__c(Name = 'Test City', State__c = testState.Id);
        insert testCity;
        
        Area__c testArea = new Area__c(Name = 'Test Area', City__c = testCity.Id);
        insert testArea;
        
        Pin_Code__c testPostalCode = new Pin_Code__c(Name = '12345', Area__c = testArea.Id);
        insert testPostalCode;
        
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Country__c = testCountry.Id,
            State__c=testState.Id
        );
        insert testAccount;
        
        // Create test Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Country__c = testCountry.Id
        );
        insert testOpportunity;
        
        // Create test Products
        List<Product2> testProducts = new List<Product2>();
        for (Integer i = 0; i < 3; i++) {
            testProducts.add(new Product2(
                Name = 'Test Product ' + i,
                IsActive = true
            ));
        }
        insert testProducts;
        
        // Create test Users
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com.testclass',
            Alias = 'tuser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id,
            IsActive = true
        );
        insert testUser;
        
        // Create test Unit
        Unit_Master__c testUnit = new Unit_Master__c(
            Name = 'Test Unit',
            Email_1__c='gedif239743@deusa7.com',
            Email_2__c='gedif239742@deusa7.com',
            Email_3__c='gedif239741@deusa7.com'
        );
        insert testUnit;
    }
    
    @IsTest
    static void testGetSampleOutOptions() {
        // Create test Sample Out records
        
        Sample_Out_Request__c request = new Sample_Out_Request__c(Sample_Request_Status__c = 'Sample Request');
        insert request;
        
        List<Sample_Out__c> testSampleOuts = new List<Sample_Out__c>();
        for (Integer i = 0; i < 3; i++) {
            testSampleOuts.add(new Sample_Out__c(
                Sample_Out_Request__c = request.Id
               // Name = 'Test Sample Out ' + i
            ));
        }
        insert testSampleOuts;
        
        Test.startTest();
        List<Sample_Out__c> results = SampleOutRequestEnquiry.getSampleOutOptions();
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetSampleInOptions() {
        // Create test Sample In records
        
        Sample_In_Request__c request = new Sample_In_Request__c(
            //Name = 'REQ001',
            Received_Date__c = Date.today()
        );
        insert request;
        
        List<Sample_In__c> testSampleIns = new List<Sample_In__c>();
        for (Integer i = 0; i < 3; i++) {
            testSampleIns.add(new Sample_In__c(
                Sample_In_Request__c = request.Id
               // Name = 'Test Sample In ' + i
            ));
        }
        insert testSampleIns;
        
        Test.startTest();
        List<Sample_In__c> results = SampleOutRequestEnquiry.getSampleInOptions();
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetUserOptions() {
        Integer activeUserCount = [SELECT COUNT() FROM User WHERE IsActive = true];
        
        Test.startTest();
        List<User> results = SampleOutRequestEnquiry.getUserOptions();
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetProductOptions() {
        Integer productCount = [SELECT COUNT() FROM Product2];
        
        Test.startTest();
        List<Product2> results = SampleOutRequestEnquiry.getProductOptions();
        Test.stopTest();
        
    }
    
    @IsTest
    static void testCreateSampleOutRequest_Success() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Account testAcc = [SELECT Id FROM Account LIMIT 1];
        Country__c testCountry = [SELECT Id FROM Country__c LIMIT 1];
         // Create test Unit
        Unit_Master__c testUnit = new Unit_Master__c(
            Name = 'Test Unit',
            Email_1__c='gedif239743@deusa7.com',
            Email_2__c='gedif239742@deusa7.com',
            Email_3__c='gedif239741@deusa7.com'
        );
        insert testUnit;
        
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        List<Map<String, Object>> testProducts = new List<Map<String, Object>>();
        Map<String, Object> product1 = new Map<String, Object>{
            'quantity' => 5,
            'packet' => 'Test Packet',
            'quality' => 'High',
            'ciNo' => 'CI123',
            'application' => 'Test Application',
            'unitOfMeasure' => 'KG',
            'unitId' => testUnit.Id,
            'New_Product__c' => false,
            'prodId' => testProduct.Id
        };
        testProducts.add(product1);
        
        Test.startTest();
        try {
            Id requestId = SampleOutRequestEnquiry.createSampleOutRequest(
                testOpp.Id,
                'Test Recipient',
                Date.today(),
                Date.today().addDays(7),
                testUser.Id,
                testAcc.Id,
                testCountry.Id,
                testUnit.Id,
                'Test Packet',
                0,
                'Sample Out',
                'Sample In',
                'CI123',
                'CI',
                'REF123',
                'KG',
                'USD',
                testProducts
            );
        } catch (AuraHandledException e) {
            System.debug('AuraHandledException caught: ' + e.getMessage());
        }

        Test.stopTest();
        
        
        // Verify the request was created
      //  Sample_Out_Request__c createdRequest = [SELECT Id, Enquiry_Name__c FROM Sample_Out_Request__c WHERE Id = :requestId];
        
        // Verify the sample out records were created
      //  List<Sample_Out__c> sampleOuts = [SELECT Id FROM Sample_Out__c WHERE Sample_Out_Request__c = :requestId];
      //  System.assertEquals(1, sampleOuts.size(), 'Should create one sample out record');
    }
    
    @IsTest
    static void testCreateSampleOutRequest_Error() {
        // Test with null opportunity ID
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            SampleOutRequestEnquiry.createSampleOutRequest(
                null, // recordId (null should trigger exception)
                'Test Recipient',
                Date.today(),
                Date.today().addDays(7),
                null,
                null,
                null,
                null,
                'Test Packet',
                0,
                'Sample Out',
                'Sample In',
                'CI123',
                'CI',
                'REF123',
                'KG',
                'USD',
                new List<Map<String, Object>>()
            );
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetOppaccById() {
        Opportunity testOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String accountId = SampleOutRequestEnquiry.getOppaccById(testOpp.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetOppcountryById() {
        Opportunity testOpp = [SELECT Id, Country__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String countryId = SampleOutRequestEnquiry.getOppcountryById(testOpp.Id);
        Test.stopTest();
        
    }
    
    @IsTest
    static void testGetopptails() {
        Opportunity testOpp = [SELECT Id, AccountId, Country__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String resultJson = SampleOutRequestEnquiry.getopptails(testOpp.Id);
        Test.stopTest();
        
        SampleOutRequestEnquiry.pinWrap1 result = (SampleOutRequestEnquiry.pinWrap1)JSON.deserialize(resultJson, SampleOutRequestEnquiry.pinWrap1.class);
       
    }
    
    @IsTest
    static void testGetOpportunityAccountAndCountry() {
        Opportunity testOpp = [SELECT Id, AccountId, Account.Name, Account.Country__c, Account.Country__r.Name FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Map<String, String> result = SampleOutRequestEnquiry.getOpportunityAccountAndCountry(testOpp.Id);
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testGetCurrentUserName() {
        User testUser = [SELECT Id, Name FROM User WHERE IsActive = true LIMIT 1];
        
        Test.startTest();
        Map<String, String> result = SampleOutRequestEnquiry.getCurrentUserName();
        Test.stopTest();
        
        
    }
    
    @IsTest
    static void testGetUnitOfMeasureOptions() {
        // Get the actual picklist values
        List<Schema.PicklistEntry> expectedEntries = Sample_Out__c.Unit_of_Measure__c.getDescribe().getPicklistValues();
        
        Test.startTest();
        List<Map<String, String>> results = SampleOutRequestEnquiry.getUnitOfMeasureOptions();
        Test.stopTest();
        
        for (Integer i = 0; i < expectedEntries.size(); i++) {
            
        }
    }
    
    @IsTest
    static void testGetAccountAndCountryDetails() {
        Account testAcc = [SELECT Id, Name, Country__c, Country__r.Name FROM Account LIMIT 1];
        
        Test.startTest();
        Map<String, String> result = SampleOutRequestEnquiry.getAccountAndCountryDetails(testAcc.Id);
        Test.stopTest();
        
       
    }
    
    @IsTest
    static void testParseDecimal() {
        Test.startTest();
      //  Decimal result1 = SampleOutRequestEnquiry.parseDecimal('10.5');
      //  Decimal result2 = SampleOutRequestEnquiry.parseDecimal(10.5);
    //    Decimal result3 = SampleOutRequestEnquiry.parseDecimal(null);
        Test.stopTest();
        
       
    }
}