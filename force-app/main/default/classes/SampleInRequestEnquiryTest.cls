@isTest
public class SampleInRequestEnquiryTest {

    @testSetup
    static void setupData() {
        // Create Country
        Country__c country = new Country__c(Name = 'India');
        insert country;

        // Create Account
        Account acc = new Account(Name = 'Test Account', Country__c = country.Id);
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today(), Country__c = country.Id);
        insert opp;

        // Create User (Running User already exists, just ensure active one is there)
        // No need to insert a new user unless you're testing impersonation

        // Create Products
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 2; i++) {
            products.add(new Product2(Name = 'Test Product ' + i));
        }
        insert products;
        
        Sample_In_Request__c request = new Sample_In_Request__c(
            //Name = 'REQ001',
            Received_Date__c = Date.today(),
            Company_Name__c = acc.Id
        );
        insert request;

        Sample_In__c sampleIn = new Sample_In__c(
            Courier_Tracking_No__c = 'TRK12345',
            Sample_Out_Ref_No__c = 'OUT12345',
            Sample_In_Request__c = request.Id,
            Quantity__c = 100
        );
        insert sampleIn;
    }

    @isTest
    static void testCreateSampleInRequest() {
        Opportunity opp = [SELECT Id, AccountId, Country__c FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        List<Map<String, Object>> productList = new List<Map<String, Object>>();
        Map<String, Object> prodMap = new Map<String, Object>{
            'productName' => 'Customer Product A',
            'application' => 'Test App',
            'ci' => 'C123',
            'srefno' => 'SRef001',
            'prodId' => prod.Id,
            'annualQtyOfBusiness' => '100.5',
            'courierno' => 'TRACK123',
            'unitId' => null,
            'quantity' => '55.55',
            'unitOfMeasure' => 'Gram (g)',
            'comment' => 'Test comment'
        };
        productList.add(prodMap);
        
         // Create a test user
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

         User testUser = new User(
            Alias = 'testusr',
            Email = 'testuserv8779879889@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuserda2324123456@example.com'
        );
        insert testUser;
        
        Test.startTest();
        Id newRequestId = SampleInRequestEnquiry.createSampleInRequest(
            opp.Id,
            'Unit A',
            Date.today(),
            Date.today(),
            UserInfo.getUserId(),
            opp.AccountId,
            opp.Country__c,
            testUser.Id, 
            'Packet A',
            1,
            'SampleOut1',
            'SampleIn1',
            'CI001',
            'CI Info',
            'SRefNo1',
            'Gram (g)',
            'No comments',
            'cu123',
            productList
        );
        Test.stopTest();
        
    }

    @isTest
    static void testGetOppaccById() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        String accId = SampleInRequestEnquiry.getOppaccById(opp.Id);
    }

    @isTest
    static void testGetOppcountryById() {
        Opportunity opp = [SELECT Id, Country__c FROM Opportunity LIMIT 1];
        String country = SampleInRequestEnquiry.getOppcountryById(opp.Id);
    }

    @isTest
    static void testGetOpptails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String result = SampleInRequestEnquiry.getopptails(opp.Id);
        
    }

    @isTest
    static void testGetOpportunityAccountAndCountry() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String, String> result = SampleInRequestEnquiry.getOpportunityAccountAndCountry(opp.Id);
        System.assert(result.containsKey('accountId'));
    }

    @isTest
    static void testGetCurrentUserName() {
        Map<String, String> result = SampleInRequestEnquiry.getCurrentUserName();
    }

    @isTest
    static void testGetPicklistAndDataMethods() {
        List<Sample_In__c> ins = SampleInRequestEnquiry.getSampleInOptions();
        List<Sample_Out__c> outs = SampleInRequestEnquiry.getSampleOutOptions();
        List<User> users = SampleInRequestEnquiry.getUserOptions();
        List<Product2> prods = SampleInRequestEnquiry.getProductOptions();
        List<Map<String, String>> uoms = SampleInRequestEnquiry.getUnitOfMeasureOptions();

       
    }
}