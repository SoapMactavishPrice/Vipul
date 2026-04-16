@isTest
public class SampleRequestMailControllerTest {
    
    @testSetup
    static void setupTestData() {
        
        User testOwner = new User(
            Alias = 'dlftest', 
            Email = 'owner@example.com', 
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id, 
            Username = 'managerdfvfdere12@example.com', 
            FirstName = 'Owner', 
            LastName = 'Test', 
            TimeZoneSidKey = 'America/New_York', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US', 
            CommunityNickname = 'owner322'
        );
        insert testOwner;
        
        Account testAccount = new Account(Name = 'Test Account',CurrencyIsoCode='USD',INCO_Terms__c = 'DDP', Email_ID__c = 'ankit@finessedirect.com');
        insert testAccount;

        
        Unit_Master__c unit = new Unit_Master__c(Name = 'AM', Email_1__c = 'ankit@finessedirect.com', Email_2__c = 'sahil@finessedirect.com');
        insert unit;
        
        Product2 testProduct = new Product2(Name = 'Test Product');
        insert testProduct;
        
        // Create test data for Sample_Request__c
        Sample_Request__c sampleRequest = new Sample_Request__c(
            Person__c = testOwner.id,
            Company_Name__c = testAccount.id,
            Request_Date__c = Date.today(),
            Received_Date__c = Date.today(),
            Sample_Sent_to_Customer_Date__c = Date.today(),
            Sample_Follow_Up_Date__c = Date.today(),
            OwnerId = UserInfo.getUserId()
        );
        insert sampleRequest;
        
        // Create test data for Sample_Out__c
        Sample_Out__c sampleOut = new Sample_Out__c(
            Sample_Sent_to_Unit__c = unit.id,
            Application__c = 'Test Application',
            Product_Name__c = testProduct.id,
            Colour_Index_Name__c = 'Test Colour',
            Quality__c = 'Test Quality',
            Quantity__c = 100,
            Sample_Request__c = sampleRequest.Id,
            Packets__c = '10',
            Unit_of_Measure__c = 'Gram (g)',
            Reference_Number__c = 'REF123'
        );
        insert sampleOut;
    }
    
   /* @isTest
    static void testSampleRequestMailController() {
        // Set the page parameters
        Test.setCurrentPage(Page.SampleRequestMailTemplate);
        ApexPages.currentPage().getParameters().put('id', [SELECT Id FROM Sample_Request__c LIMIT 1].Id);
        
        // Instantiate the controller
        SampleRequestMailController controller = new SampleRequestMailController();
        
        
        // Test saveAndSend method
        Test.startTest();
        PageReference result = controller.saveAndSend();
        Test.stopTest();
        
        result = controller.cancel();
        
    }*/
}