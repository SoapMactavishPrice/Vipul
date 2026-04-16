@isTest
public class SampleRequestEmailSenderTest {
    @testSetup
    static void setup() {
        // Create test data for Sample_Request__c
        // 
        User testOwner = new User(
            Alias = 'dlftest', 
            Email = 'owner@example.com', 
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id, 
            Username = 'managerhgvyggv12@example.com', 
            FirstName = 'Owner', 
            LastName = 'Test', 
            TimeZoneSidKey = 'America/New_York', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US', 
            CommunityNickname = 'owner'
        );
        insert testOwner;
        
        Account testAccount = new Account(Name = 'Test Account',CurrencyIsoCode='USD',INCO_Terms__c = 'DDP');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;

        Sample_Request__c sampleRequest = new Sample_Request__c(
            Enquiry__c = testOpportunity.Id,
            Person__c = testOwner.id
        );
        insert sampleRequest;
        
         Product2 testProduct = new Product2(Name = 'Test Product');
        insert testProduct;
        
        Unit_Master__c unit = new Unit_Master__c(Name = 'AM', Email_1__c = 'ankit@finessedirect.com', Email_2__c = 'sahil@finessedirect.com');
        insert unit;

        // Create test data for Sample_In__c
        Sample_In__c sampleIn = new Sample_In__c( Sample_Request__c = sampleRequest.Id, Sample_Sent_to_Unit__c = unit.Id, VOL_Product_Name__c = testProduct.id, C_I__c = 'CI-001', Application__c = 'Application 1');
        insert sampleIn;

        // Create test data for Sample_Out__c
        Sample_Out__c sampleOut = new Sample_Out__c( Sample_Request__c = sampleRequest.Id, Sample_Sent_to_Unit__c = unit.Id, Product_Name__c = testProduct.Id, Colour_Index_Name__c = 'CI-002', Quality__c = 'Quality 1', Quantity__c = 100, Application__c = 'Application 2');
        insert sampleOut;

    }

    @isTest
    static void testSendEmailAsync() {
        Test.startTest();
        
        Sample_Request__c sampleRequest = [select id, Person__c from Sample_Request__c limit 1];
        
        // Call the method to be tested
        SampleRequestEmailSender.sendEmailAsync(sampleRequest.id);
        
        Test.stopTest();
    }
}