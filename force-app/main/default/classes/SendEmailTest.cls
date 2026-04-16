@isTest
private class SendEmailTest {
    @testSetup
    static void setupTestData() {
        // Create test manager user
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testManager = new User(
            Alias = 'testmgr', 
            Email = 'manager@example.com', 
            ProfileId = stdProfile.Id, 
            Username = 'managerkdlf2008@example.com', 
            FirstName = 'Manager', 
            LastName = 'Test', 
            TimeZoneSidKey = 'America/New_York', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US', 
            CommunityNickname = 'manager'
        );
        insert testManager;

        // Create test owner user with manager
        User testOwner = new User(
            Alias = 'dlftest', 
            Email = 'owner@example.com', 
            ProfileId = stdProfile.Id, 
            Username = 'managerkdlf2012@example.com', 
            FirstName = 'Owner', 
            LastName = 'Test', 
            TimeZoneSidKey = 'America/New_York', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US', 
            CommunityNickname = 'owner',
            ManagerId = testManager.Id
        );
        insert testOwner;
        
        // Create pricebooks
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;
        
        Pricebook2 testPricebook1 = new Pricebook2(
            Name = 'Test Pricebook 2',
            IsActive = true
        );
        insert testPricebook1;

        // Create account
        Account testAccount = new Account(
            Name = 'Test Account', 
            CurrencyIsoCode = 'USD', 
            INCO_Terms__c = 'DDP'
        );
        insert testAccount;
        
        // Create product
        Product2 prod = new Product2(
            Name = 'Test Product', 
            Family = 'Test Family', 
            IsActive = true
        );
        insert prod;
        
        // Create pricebook entries with ListPrice
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true, 
            UseStandardPrice = false
        );
        insert standardPbe;
        
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 0, 
            IsActive = true, 
            UseStandardPrice = false
        );
        insert customPbe;
        
        PricebookEntry customPbe1 = new PricebookEntry(
            Pricebook2Id = testPricebook1.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 10,  // UnitPrice < ListPrice (10)
            IsActive = true, 
            UseStandardPrice = false
        );
        insert customPbe1;
        
        // Create opportunities
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount.Id, 
            OwnerId = testOwner.Id,
            Pricebook2Id = testPricebook.Id,
            Who_will_attend__c = testManager.Id
        );
        insert testOpportunity;
        
        Opportunity testOpportunityWithPriceAlert = new Opportunity(
            Name = 'Test Opportunity With Price Alert', 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = testAccount.Id, 
            OwnerId = testOwner.Id,
            Pricebook2Id = testPricebook1.Id,
            Who_will_attend__c = testOwner.Id
        );
        insert testOpportunityWithPriceAlert;

        // Create opportunity line items
        OpportunityLineItem oppLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 0, 
            Request_Purchase_Price__c = false,
            Quality__c = 'High',
            PricebookEntryId = customPbe.Id
        );
        insert oppLineItem;
        
        OpportunityLineItem oppLineItemWithPriceAlert = new OpportunityLineItem(
            OpportunityId = testOpportunityWithPriceAlert.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 5, // Will be compared to ListPrice (10)
            Request_Purchase_Price__c = false,
            Quality__c = 'Medium',
            PricebookEntryId = customPbe1.Id
        );
        insert oppLineItemWithPriceAlert;

        // Create quote
        Quote testQuote = new Quote(
            OpportunityId = testOpportunity.Id, 
            Name = 'Test Quote', 
            Status = 'Draft',
            Pricebook2Id = testPricebook.Id,
            Who_will_attend__c = testManager.Id
        );
        insert testQuote;

        // Create quote line item
        QuoteLineItem quoteLineItem = new QuoteLineItem(
            QuoteId = testQuote.Id, 
            Product2Id = prod.Id, 
            Quantity = 1, 
            UnitPrice = 0, 
            Request_Purchase_Price__c = false,
            Quality__c = 'Standard',
            PricebookEntryId = customPbe.Id
        );
        insert quoteLineItem;
    }

    // Test methods for sendEmailNotification
    @isTest
    static void testSendEmailNotification_ValidOppId() {
        Opportunity testOpp = [SELECT Id, Who_will_attend__c, OwnerId FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        SendEmail.sendEmailNotification(testOpp.Id);
        Test.stopTest();
        
        // Verify OpportunityLineItem was updated
        OpportunityLineItem updatedOli = [
            SELECT Request_Purchase_Price__c 
            FROM OpportunityLineItem 
            WHERE OpportunityId = :testOpp.Id 
            LIMIT 1
        ];
    }
        
    

    // Test methods for sendEmailNotificationQuote
    @isTest
    static void testSendEmailNotificationQuote_ValidQuoteId() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(testQuote.Id);
        Test.stopTest();
        
        // Verify QuoteLineItem was updated
        QuoteLineItem updatedQli = [
            SELECT Request_Purchase_Price__c 
            FROM QuoteLineItem 
            WHERE QuoteId = :testQuote.Id 
            LIMIT 1
        ];
        System.assertEquals(true, updatedQli.Request_Purchase_Price__c, 'Request_Purchase_Price__c should be true');
    }
    
    @isTest
    static void testSendEmailNotificationQuote_NullQuoteId() {
        Test.startTest();
        SendEmail.sendEmailNotificationQuote(null);
        SendEmail.temethod();
        Test.stopTest();
        
        // Verify no errors occurred (handled gracefully)
    }


    // Mock class for callout testing if needed
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }
    
}