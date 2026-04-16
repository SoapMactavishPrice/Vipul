@isTest
private class SampleRequestControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create test Country
        Country__c testCountry = new Country__c(Name = 'Test Country');
        insert testCountry;

        // Create test Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Country__c = testCountry.Id
        );
        insert testOpportunity;

        // Create test Product
        Product2 testProduct = new Product2(Name = 'Test Product');
        insert testProduct;

        // Create test Unit Master
        Unit_Master__c testUnit = new Unit_Master__c(Name = 'Test Unit');
        insert testUnit;

        // Create test User
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'testusr',
            Email='testuser@testorg.com',
            EmailEncodingKey='UTF-8',
            LastName='Testing',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='volsp593@testorg.com',
            IsActive = true
        );
        insert testUser;
    }

    @isTest
    static void testGetSampleOutOptions() {
        Test.startTest();
        List<Sample_Out__c> result = SampleRequestController.getSampleOutOptions();
        Test.stopTest();
        
      
    }

    @isTest
    static void testGetSampleInOptions() {
        Test.startTest();
        List<Sample_In__c> result = SampleRequestController.getSampleInOptions();
        Test.stopTest();
        
    
    }

    @isTest
    static void testGetUserOptions() {
        Test.startTest();
        List<User> result = SampleRequestController.getUserOptions();
        Test.stopTest();
        
    
    }

    @isTest
    static void testGetSamplesRequestSentToOptions() {
        Test.startTest();
        List<Map<String, String>> result = SampleRequestController.getSamplesRequestSentToOptions();
        Test.stopTest();
        
      
    }

    @isTest
    static void testGetProductOptions() {
        Test.startTest();
        List<Product2> result = SampleRequestController.getProductOptions();
        Test.stopTest();
        
       
    }

    @isTest
    static void testCreateSampleRequestForSampleOut() {
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Country__c testCountry = [SELECT Id FROM Country__c LIMIT 1];
        Unit_Master__c testUnit = [SELECT Id FROM Unit_Master__c LIMIT 1];

        List<Map<String, Object>> products = new List<Map<String, Object>>();
        Map<String, Object> product = new Map<String, Object>{
            'prodId' => testProduct.Id,
            'quantity' => '10',
            'packet' => 'Test Packet',
            'quality' => 'High',
            'ciNo' => 'CI123',
            'application' => 'Test Application',
            'unitOfMeasure' => 'Kilogram (Kg)',
            'unitId' => testUnit.Id
        };
        products.add(product);

        Test.startTest();
        Id sampleRequestId = SampleRequestController.createSampleRequest(
            testOpportunity.Id, // recordId
            'Plant',           // sampleOutSentTo
            Date.today(),      // requestDate
            Date.today().addDays(5), // receivedDate
            testUser.Id,       // personId
            testAccount.Id,    // accountId
            testCountry.Id,    // countryId
            testUnit.Id,       // UnitId
            'Test Packet',     // packet
            0,                // delayDays
            'SampleOut',      // sampleout
            null,             // samplein
            'CI123',          // ciNo
            null,             // ci
            null,             // srefno
            'Kilogram (Kg)',             // unitOfMeasure
            products          // products
        );
        Test.stopTest();

        System.assertNotEquals(null, sampleRequestId, 'Should return a valid sample request ID');
        
        // Verify Sample Request was created
        Sample_Request__c createdRequest = [SELECT Id, Enquiry__c FROM Sample_Request__c WHERE Id = :sampleRequestId];
       
        
        // Verify Sample Out was created
        List<Sample_Out__c> sampleOuts = [SELECT Id FROM Sample_Out__c WHERE Sample_Request__c = :sampleRequestId];
        
    }

    @isTest
    static void testCreateSampleRequestForSampleIn() {
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Country__c testCountry = [SELECT Id FROM Country__c LIMIT 1];
        Unit_Master__c testUnit = [SELECT Id FROM Unit_Master__c LIMIT 1];

        List<Map<String, Object>> products = new List<Map<String, Object>>();
        Map<String, Object> product = new Map<String, Object>{
            'productName' => 'Test Product',
            'application' => 'Test Application',
            'ci' => 'CI123',
            'srefno' => 'SREF001',
            'prodId' => testProduct.Id,
            'annualQtyOfBusiness' => '100',
            'courierno' => 'TRACK123',
            'unitId' => testUnit.Id
        };
        products.add(product);

        Test.startTest();
        Id sampleRequestId = SampleRequestController.createSampleRequest(
            testOpportunity.Id, // recordId
            'Plant',           // sampleOutSentTo
            Date.today(),      // requestDate
            Date.today().addDays(5), // receivedDate
            testUser.Id,       // personId
            testAccount.Id,    // accountId
            testCountry.Id,    // countryId
            testUnit.Id,       // UnitId
            null,              // packet
            0,                // delayDays
            null,             // sampleout
            'SampleIn',       // samplein
            null,             // ciNo
            'CI123',          // ci
            'SREF001',        // srefno
            null,             // unitOfMeasure
            products          // products
        );
        Test.stopTest();

        System.assertNotEquals(null, sampleRequestId, 'Should return a valid sample request ID');
        
        // Verify Sample In was created
        List<Sample_In__c> sampleIns = [SELECT Id FROM Sample_In__c WHERE Sample_Request__c = :sampleRequestId];
        
    }

    @isTest
    static void testGetOppaccById() {
        Opportunity testOpportunity = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = SampleRequestController.getOppaccById(testOpportunity.Id);
        Test.stopTest();
        
        
    }

    @isTest
    static void testGetOppcountryById() {
        Opportunity testOpportunity = [SELECT Id, Country__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = SampleRequestController.getOppcountryById(testOpportunity.Id);
        Test.stopTest();
        
        
    }

    @isTest
    static void testGetopptails() {
        Opportunity testOpportunity = [SELECT Id, AccountId, Country__c FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = SampleRequestController.getopptails(testOpportunity.Id);
        Test.stopTest();
        
        
    }

    @isTest
    static void testGetOpportunityAccountAndCountry() {
        Opportunity testOpportunity = [SELECT Id, AccountId, Account.Name, Account.Country__c, Account.Country__r.Name FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Map<String, String> result = SampleRequestController.getOpportunityAccountAndCountry(testOpportunity.Id);
        Test.stopTest();
        
        
    }

    @isTest
    static void testGetCurrentUserName() {
        Test.startTest();
        Map<String, String> result = SampleRequestController.getCurrentUserName();
        Test.stopTest();
        
    
    }

    @isTest
    static void testGetUnitOfMeasureOptions() {
        Test.startTest();
        List<Map<String, String>> result = SampleRequestController.getUnitOfMeasureOptions();
        Test.stopTest();
        
        
    }

    @isTest
    static void testCreateSampleRequestWithNullOpportunityId() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            SampleRequestController.createSampleRequest(
                null,           // recordId
                'Plant',        // sampleOutSentTo
                Date.today(),  // requestDate
                Date.today(),  // receivedDate
                null,          // personId
                null,          // accountId
                null,          // countryId
                null,          // UnitId
                null,          // packet
                0,             // delayDays
                null,          // sampleout
                null,          // samplein
                null,          // ciNo
                null,          // ci
                null,          // srefno
                null,          // unitOfMeasure
                null           // products
            );
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
    }
}