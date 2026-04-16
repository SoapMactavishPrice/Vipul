@isTest
private class QuoteStatusEmailHelperTest {

    @testSetup
    static void setupTestData() {
        // Create Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create Custom Pricebook
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;

        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', Family = 'Test Family', IsActive = true);
        insert prod;

        // Create Pricebook Entries
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardPbe;

        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert customPbe;

        // Create Account
        Account testAccount = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD', INCO_Terms__c = 'DDP');
        insert testAccount;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = testAccount.Id
        );
        insert opp;

        // Create Quote
        Quote quote = new Quote(Name = 'Test Quote', 
            OpportunityId = opp.Id,
            Pricebook2Id = testPricebook.Id, 
            CurrencyIsoCode = 'USD'
        );
        insert quote;

        // Insert QuoteLineItems, linking with the PricebookEntry created earlier
        QuoteLineItem qli1 = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = customPbe.Id, // Linking to PricebookEntry
            Quantity = 10,
            Purchase_Price_Status__c = 'Approved',
            Purchase_Price_in_INR__c = 500,
            UnitPrice = 123
        );
        insert qli1;

        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = customPbe.Id, // Linking to PricebookEntry
            Quantity = 5,
            Purchase_Price_Status__c = 'Rejected',
            Reject_Reason__c = 'Price too high',
            Purchase_Price_in_INR__c = 450,
            UnitPrice = 123
        );
        insert qli2;
    }

    @isTest
    static void testSendQuoteStatusEmails() {
        // Retrieve the test quote
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];

        // Create list of Quote Ids to pass to the helper method
        List<Id> quoteIds = new List<Id>{testQuote.Id};

        Test.startTest();
        // Call the method to send email notifications for quote status
        QuoteStatusEmailHelper.sendQuoteStatusEmails(quoteIds);
        Test.stopTest();
    }
}