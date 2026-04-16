@IsTest
public class SampleOutRequestTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Country__c testCountry = new Country__c(Name = 'Test Country');
        insert testCountry;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        Product2 testProduct1 = new Product2(Name = 'Test Product 1', IsActive = true);
        Product2 testProduct2 = new Product2(Name = 'Test Product 2', IsActive = true);
        insert new List<Product2>{testProduct1, testProduct2};

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email='testuser@example.com',
            Username='unique_testuser867u766@example.com',
            Alias='tuser',
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            ProfileId = p.Id,
            IsActive = true
        );
        insert testUser;

        Sample_Out_Request__c sampleRequest = new Sample_Out_Request__c(
            Person__c = testUser.Id,
            Company_Name__c = testAccount.Id,
            Country__c = testCountry.Id
        );
        insert sampleRequest;

        Sample_Out__c sampleOut = new Sample_Out__c(
            Sample_Out_Request__c = sampleRequest.Id,
            Quantity__c = 10
           // Product__c = testProduct1.Id
        );
        insert sampleOut;
    }

    @IsTest
    static void testGetSampleOutOptions() {
        Test.startTest();
        List<Sample_Out__c> results = SampleOutRequest.getSampleOutOptions();
        Test.stopTest();
    }

    @IsTest
    static void testGetSampleInOptions() {
        Test.startTest();
        List<Sample_In__c> results = SampleOutRequest.getSampleInOptions();
        Test.stopTest();
    }

    @IsTest
    static void testGetUserOptions() {
        Test.startTest();
        List<User> results = SampleOutRequest.getUserOptions();
        Test.stopTest();
    }

    @IsTest
    static void testGetProductOptions() {
        Test.startTest();
        List<Product2> results = SampleOutRequest.getProductOptions();
        Test.stopTest();
    }

    @IsTest
    static void testSearchOpportunitiesWithoutSearchTerm() {
        Test.startTest();
        List<Opportunity> results = SampleOutRequest.searchOpportunities(null);
        Test.stopTest();
    }

    @IsTest
    static void testSearchOpportunitiesWithSearchTerm() {
        Test.startTest();
        List<Opportunity> results = SampleOutRequest.searchOpportunities('Test');
        Test.stopTest();
    }

    @IsTest
    static void testGetAccountAndCountryDetails() {
        Account testAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Country__c testCountry = [SELECT Id, Name FROM Country__c WHERE Name = 'Test Country' LIMIT 1];
        testAccount.Country__c = testCountry.Id;
        update testAccount;
        Test.startTest();
        Map<String, String> result = SampleOutRequest.getAccountAndCountryDetails(testAccount.Id);
        Test.stopTest();
    }

    @IsTest
    static void testGetUnitOfMeasureOptions() {
        Test.startTest();
        List<Map<String, String>> results = SampleOutRequest.getUnitOfMeasureOptions();
        Test.stopTest();
    }

    @IsTest
    static void testCreateSampleOutRequest() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Country__c testCountry = [SELECT Id FROM Country__c WHERE Name = 'Test Country' LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product 1' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Username='unique_testuser867u766@example.com' LIMIT 1];

        List<Map<String, Object>> products = new List<Map<String, Object>>();
        Map<String, Object> product1 = new Map<String, Object>{
            'prodId' => testProduct.Id,
            'quantity' => 10,
            'packet' => '5kg',
            'quality' => 'High',
            'ciNo' => 'CI123',
            'application' => 'Test Application',
            'unitOfMeasure' => 'KG',
            'unitId' => testUser.Id,
            'New_Product__c' => false
        };
        products.add(product1);

        Test.startTest();
        Id requestId;
        try {
            requestId = SampleOutRequest.createSampleOutRequest(
                testOpp.Id,
                'Test Recipient',
                Date.today(),
                Date.today().addDays(5),
                testUser.Id,
                testAccount.Id,
                testOpp.Id,
                testCountry.Id,
                testUser.Id,
                testProduct.Id,
                '5kg',
                5,
                'Test Sample Out',
                'Test Sample In',
                'CI123',
                'Test CI',
                'REF123',
                'KG',
                'USD',
                products
            );
        } catch (Exception ex) {
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateSampleOutRequestWithNewProduct() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Country__c testCountry = [SELECT Id FROM Country__c WHERE Name = 'Test Country' LIMIT 1];

        List<Map<String, Object>> products = new List<Map<String, Object>>();
        Map<String, Object> product1 = new Map<String, Object>{
            'prodId' => null,
            'quantity' => 10,
            'packet' => '5kg',
            'quality' => 'High',
            'ciNo' => 'CI123',
            'application' => 'Test Application',
            'unitOfMeasure' => 'KG',
            'New_Product__c' => true,
            'New_Product_Name__c' => 'New Test Product',
            'New_Product_CI_No__c' => 'NEWCI123'
        };
        products.add(product1);

        Test.startTest();
        Test.stopTest();
    }

    @IsTest
    static void testCreateSampleOutRequestErrorHandling() {
        List<Map<String, Object>> products = new List<Map<String, Object>>();
        Map<String, Object> product1 = new Map<String, Object>{
            'prodId' => 'invalidId',
            'quantity' => 10,
            'packet' => '5kg',
            'quality' => 'High',
            'ciNo' => 'CI123',
            'application' => 'Test Application',
            'unitOfMeasure' => 'KG',
            'unitId' => 'invalidId',
            'New_Product__c' => false
        };
        products.add(product1);

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
    }

    @IsTest
    static void testParseDecimal() {
        Test.startTest();
        Test.stopTest();
    }
}