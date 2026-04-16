@isTest
public class QuoteLineItemTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account', INCO_Terms__c = 'DDP');
        insert testAccount;

        // Create a test Opportunity linked to the Account
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;

        // Query the Standard Pricebook (fixed IsStandard issue)
        Pricebook2 standardPricebook = new Pricebook2(
            Id=Test.getstandardPricebookId(),
            IsActive=True);
        update standardPricebook;

        // Assign the Standard Pricebook to the Opportunity
        testOpportunity.Pricebook2Id = standardPricebook.Id;
        update testOpportunity;

        // Create a test Quote linked to the Opportunity **with Pricebook assigned**
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            Pricebook2Id = standardPricebook.Id // FIX: Assign the Pricebook to the Quote
        );
        insert testQuote;

        // Create a test Product2
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        // Create a PricebookEntry for the Product
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = standardPricebook.Id, // Use the same Pricebook as Quote
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;

        // Create a QuoteLineItem record
        QuoteLineItem testQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testQLI;
    }
    
    @isTest
    static void testBeforeInsertTrigger() {
        // Fetch test Quote and PricebookEntry
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        PricebookEntry testPricebookEntry = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create a new QuoteLineItem
        QuoteLineItem newQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 2,
            UnitPrice = 200
        );

        Test.startTest();
        insert newQLI;
        Test.stopTest();

        // Retrieve inserted QuoteLineItem
        QuoteLineItem insertedQLI = [SELECT Id, Quantity, UnitPrice FROM QuoteLineItem WHERE Id = :newQLI.Id LIMIT 1];

    }

    @isTest
    static void testBeforeUpdateTrigger() {
        // Fetch test QuoteLineItem
        QuoteLineItem testQLI = [SELECT Id, Quantity, UnitPrice FROM QuoteLineItem LIMIT 1];

        // Update the Quantity
        testQLI.Quantity = 3;

        Test.startTest();
        update testQLI;
        Test.stopTest();

        // Retrieve updated QuoteLineItem
        QuoteLineItem updatedQLI = [SELECT Id, Quantity FROM QuoteLineItem WHERE Id = :testQLI.Id LIMIT 1];

    }

    @isTest
    static void testAfterUpdateTrigger() {
        // Fetch test QuoteLineItem
        QuoteLineItem testQLI = [SELECT Id, Quantity, UnitPrice FROM QuoteLineItem LIMIT 1];

        // Update the Unit Price
        testQLI.UnitPrice = 250;

        Test.startTest();
        update testQLI;
        Test.stopTest();

        // Retrieve updated QuoteLineItem
        QuoteLineItem updatedQLI = [SELECT Id, UnitPrice FROM QuoteLineItem WHERE Id = :testQLI.Id LIMIT 1];

    }
}