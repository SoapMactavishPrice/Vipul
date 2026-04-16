@isTest
private class PriceStatusEmailHelperTest {

    @TestSetup
    static void setupTestData() {
        // Create a test account
        Account testAccount = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD',INCO_Terms__c = 'DDP');
        insert testAccount;
        
        // Create a custom Pricebook2 (in case the standard one is not available)
        Id standardPricebookId = Test.getStandardPricebookId();

        // Create a test user
        User testUser = new User(
            Username = 'runout99zzxzz@example.com',
            Alias = 'testuser',
            Email = 'runoutasasa99@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'User',
            IsActive = true
        );
        insert testUser;

        // Create an opportunity and link it to the created account and user
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            OwnerId = testUser.Id
        );
        insert testOpportunity;

        

        // Associate the Opportunity with the custom Pricebook
        testOpportunity.Pricebook2Id = standardPricebookId;
        update testOpportunity;

        // Create a product
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = TRUE);
        insert testProduct;

        // Create PricebookEntry for the Product in the custom Pricebook
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,  // Set an example price
            IsActive = true
        );
        insert testPricebookEntry;

        // Create OpportunityLineItem records and associate them with the PricebookEntry
        OpportunityLineItem testOli1 = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntry.Id,  // Use PricebookEntryId
            Purchase_Price_Status__c = 'Approved',
            Quantity = 10,
            Purchase_Price_in_INR__c = 1000,
            TotalPrice = 10000
        );
        insert testOli1;

        OpportunityLineItem testOli2 = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntry.Id,  // Use PricebookEntryId
            Purchase_Price_Status__c = 'Rejected',
            Quantity = 5,
            Reject_Reason__c = 'Price too high',
            TotalPrice = 10000
        );
        insert testOli2;
    }

    @isTest
    static void testSendPriceStatusEmails() {
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        List<Id> oppIds = new List<Id>{ testOpportunity.Id };

        Test.startTest();
        PriceStatusEmailHelper.sendPriceStatusEmails(oppIds);
        Test.stopTest();
    }
}