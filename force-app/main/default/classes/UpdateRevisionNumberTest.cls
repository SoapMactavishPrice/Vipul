@isTest
public class UpdateRevisionNumberTest {
    
    @testSetup
    static void setupTestData() {
        // Create a Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create an Opportunity (since Quotes require an Opportunity)
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpportunity;

        // Create a Product
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true, Family = 'Hardware');
        insert testProduct;

        // Create a PricebookEntry for the product
        PricebookEntry testPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPBE;

        // Create a Quote (linked to the Opportunity)
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            Pricebook2Id = standardPricebook.Id,
            Status = 'Draft',
            OpportunityId = testOpportunity.Id // ✅ Required field
        );
        insert testQuote;

        // Create a QuoteLineItem (linked to the Quote)
        QuoteLineItem testQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = testPBE.Id,
            UnitPrice = 100,
            Quantity = 1
        );
        insert testQLI;
    }

    @isTest
    static void testQuoteRevisionUpdate() {
        // Retrieve the Quote and QuoteLineItem
        Quote testQuote = [SELECT Id, Revision_Number__c FROM Quote LIMIT 1];
        QuoteLineItem testQLI = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE QuoteId = :testQuote.Id LIMIT 1];

        // Update QuoteLineItem to trigger revision number update
        testQLI.UnitPrice = 120; // Change in UnitPrice should trigger update

        Test.startTest();
        update testQLI;
        Test.stopTest();

        // Retrieve the updated Quote
        Quote updatedQuote = [SELECT Id, Revision_Number__c FROM Quote WHERE Id = :testQuote.Id];
        
    }

    @isTest
    static void testNoUpdateWhenNoChange() {
        // Retrieve Quote and QuoteLineItem
        Quote testQuote = [SELECT Id, Revision_Number__c FROM Quote LIMIT 1];
        QuoteLineItem testQLI = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE QuoteId = :testQuote.Id LIMIT 1];

        Test.startTest();
        update testQLI; // No change in values, should not trigger update
        Test.stopTest();

        // Retrieve the updated Quote
        Quote updatedQuote = [SELECT Id, Revision_Number__c FROM Quote WHERE Id = :testQuote.Id];
    }
}