@isTest
public class SampleInRequestTest {
    
    @testSetup
    static void setupData() {
        User usr = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        Contact con = new Contact(LastName = 'Test Contact', Email = 'test@example.com');
        insert con;
        
        Country__c country = new Country__c(Name = 'India');
        insert country;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        Account acc = new Account(Name = 'Test Account', Country__c = country.Id);
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', CloseDate = Date.today(), StageName = 'Prospecting', AccountId = acc.Id);
        insert opp;
        
        // Create Sample_Out__c and Sample_In__c for use in other tests
        Sample_Out__c sampleOut = new Sample_Out__c();
        insert sampleOut;
        
        Sample_In__c sampleIn = new Sample_In__c();
        insert sampleIn;
    }
    
    @isTest
    static void testGetSampleOutOptions() {
        Test.startTest();
        List<Sample_Out__c> result = SampleInRequest.getSampleOutOptions();
        Test.stopTest();
    }
    
    @isTest
    static void testGetSampleInOptions() {
        Test.startTest();
        List<Sample_In__c> result = SampleInRequest.getSampleInOptions();
        Test.stopTest();
    }
    
    @isTest
    static void testGetUserOptions() {
        Test.startTest();
        List<User> users = SampleInRequest.getUserOptions();
        Test.stopTest();
    }
    
    @isTest
    static void testGetProductOptions() {
        Test.startTest();
        List<Product2> products = SampleInRequest.getProductOptions();
        Test.stopTest();
    }
    
    @isTest
    static void testSearchOpportunities() {
        Test.startTest();
        List<Opportunity> opportunities = SampleInRequest.searchOpportunities('Test');
        Test.stopTest();
    }
    
    @isTest
    static void testGetAccountAndCountryDetails() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Test.startTest();
        Map<String, String> details = SampleInRequest.getAccountAndCountryDetails(accountId);
        Test.stopTest();
    }
    
    @isTest
    static void testGetCurrentUserName() {
        Test.startTest();
        Map<String, String> userInfo = SampleInRequest.getCurrentUserName();
        Test.stopTest();
    }
    
    @isTest
    static void testGetUnitOfMeasureOptions() {
        Test.startTest();
        List<Map<String, String>> options = SampleInRequest.getUnitOfMeasureOptions();
        Test.stopTest();
    }
    
   /* @isTest
    static void testCreateSampleInRequest_Exception() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Map<String, Object>> products = new List<Map<String, Object>>();
        Map<String, Object> product = new Map<String, Object>{
            'productName' => 'Customer Product',
                'application' => 'Test Application',
                'ci' => 'CI123',
                'srefno' => 'SR123',
                'prodId' => prod.Id,
                'annualQtyOfBusiness' => 500,
                'courierno' => 'TRK123456',
                'unitId' => acc.Id,
                'quantity' => 100,
                'unitOfMeasure' => 'Gram (g)',
                'comment' => 'Sample Comment',
                'custRef' => 'CUST123'
                };
                    products.add(product);
        
        Test.startTest();
        try {
            // Intentionally passing null to cause an exception
            Id newRequestId = SampleInRequest.createSampleInRequest(
                null,
                acc.Id,
                Date.today(),
                Date.today(),
                con.Id,
                acc.Id,
                opp.Id,
                country.Id,
                acc.Id,
                'Test Packet',
                2,
                'SampleOutRef',
                'SampleInRef',
                'CI123',
                'CI',
                'SREF123',
                'Gram (g)',
                'Test Comment',
                'cus123',
                products
            );
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }*/
    
    @isTest
    static void testCreateSampleInRequest_Success() {
        // Create necessary test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(LastName = 'Test Contact');
        insert con;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', CloseDate = Date.today().addDays(30), StageName = 'New');
        insert opp;

        Country__c country = new Country__c(Name = 'Test Country');
        insert country;

        Unit_Master__c unit = new Unit_Master__c(Name = 'Test Unit');
        insert unit;

        Product2 prod = new Product2(Name = 'Test Product');
        insert prod;

        Opportunity enquiry = new Opportunity(Name = 'Test Enquiry', CloseDate = Date.today().addDays(30), StageName = 'New');
        insert enquiry;
        
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

         User testUser = new User(
            Alias = 'testusr',
            Email = 'testuserv8as779879889@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuserda2asa324123456@example.com'
        );
        insert testUser;

        // Create sample products list
        List<Map<String, Object>> products = new List<Map<String, Object>>();

        Map<String, Object> product1 = new Map<String, Object>{
            'productName' => 'Product A',
            'application' => 'App A',
            'ci' => 'CI123',
            'srefno' => 'SREF001',
            'prodId' => prod.Id,
            'annualQtyOfBusiness' => 100.5,
            'courierno' => 'TRACK123',
            'unitId' => unit.Id,
            'quantity' => 50,
            'unitOfMeasure' => 'Gram (g)',
            'comment' => 'Sample Comment',
            'custRef' => 'CUST123'
        };

        products.add(product1);

        Test.startTest();
        Id sampleInRequestId = SampleInRequest.createSampleInRequest(
            opp.Id,
            'Unit A',
            Date.today(),
            Date.today().addDays(5),
            testUser.Id,
            acc.Id,
            enquiry.Id,
            country.Id,
            unit.Id,
            'Packets',
            2.0,
            'SampleOut',
            'SampleIn',
            'CINO',
            'CI VAL',
            'SREFNO',
            'Gram (g)',
            'Comment',
            'CustRefNo',
            products
        );
        Test.stopTest();

        // Validate Sample In Request created
        Sample_In_Request__c request = [SELECT Id, Person__c, Company_Name__c, Enquiry_Name__c, Country__c FROM Sample_In_Request__c WHERE Id = :sampleInRequestId];

        // Validate Sample In record
        List<Sample_In__c> sampleInList = [SELECT Id, VOL_Product_Name__c, Quantity__c, Customer_s_Product_Name__c FROM Sample_In__c WHERE Sample_In_Request__c = :sampleInRequestId];
    }
}