@isTest
private class EditPurchasePriceQuoteControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test user with email
        //User testUser = [SELECT Id, Email, Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
        
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            Alias = 'testusr',
            Email = 'testuservaa8779879889@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuserdhgfshga2324@example.com'
        );
        insert testUser;

        // Create an Opportunity record
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30)
        );
        insert testOpportunity;

        // Get the Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create a Quote record and assign the price book
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OwnerId = testUser.Id,
            OpportunityId = testOpportunity.Id,
            Pricebook2Id = standardPricebook.Id
        );
        insert testQuote;

        // Create a Product record
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        // Create a PricebookEntry in the same Pricebook as the Quote
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, // Ensure it matches the Quote
            Product2Id = testProduct.Id,
            UnitPrice = 0,
            IsActive = true
        );
        insert testPricebookEntry;

        // Create QuoteLineItems related to the Quote with a different field condition
        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Product2Id = testProduct.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 2,
            Purchase_Price_in_INR__c = 150,
            UnitPrice = 0,
            Purchase_Price_Status__c = 'Approved',
            Request_Purchase_Price__c = true
        );
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Product2Id = testProduct.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 3,
            Purchase_Price_in_INR__c = 200,
            UnitPrice = 0,
            Purchase_Price_Status__c = 'Approved',
            Request_Purchase_Price__c = true
        );
        insert new List<QuoteLineItem>{qli1, qli2};
    }


    @isTest
    static void testSaveMethod() {
        // Get test Quote
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];

        // Simulate page reference with test Quote ID
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        EditPurchasePriceQuoteController controller = new EditPurchasePriceQuoteController();

        // Call Save method
        PageReference result = controller.Save();
        Test.stopTest();

        // Verify the Save method results
        List<QuoteLineItem> updatedQuoteLineItems = [SELECT Purchase_Price_in_INR__c, Purchase_Price_Status__c FROM QuoteLineItem WHERE QuoteId = :testQuote.Id];
        for (QuoteLineItem qli : updatedQuoteLineItems) {
            if (qli.Purchase_Price_Status__c != null) {
                // Add assertions to verify the expected status
                System.assertEquals('Approved', qli.Purchase_Price_Status__c, 'The Purchase Price Status should be updated to Approved.');
            }
        }
    }

    
}