@isTest
public class QuoteLineItemTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create an Opportunity record
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30)
        );
        insert opp;

        // Get the Standard Pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id= Test.getStandardPricebookId(),
            IsActive= true
        );
        update standardPricebook; 

        // Create a Product2 record
        Product2 prod = new Product2(Name = 'Test Product', isActive = true);
        insert prod;

        // Create a PricebookEntry in the Standard Pricebook
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, // Assign to Standard Pricebook
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create a Quote and assign the same Pricebook2Id
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebook.Id // Assigning the same price book
        );
        insert quote;

        // Create QuoteLineItem record
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Purchase_Price_in_INR__c = 60
        );
        insert qli;
    }

    @isTest
    static void testUpdateDescription() {
        List<QuoteLineItem> qlis = [SELECT Id, Product2Id, Description, ListPrice FROM QuoteLineItem];

        Test.startTest();
        QuoteLineItemTriggerHandler.updateDescription(qlis);
        Test.stopTest();
    }

    @isTest
    static void testCalculateUnitPrice() {
        List<QuoteLineItem> qlis = [SELECT Id, UnitPrice, Converted_Purchase_Price__c, Margin_Amount__c, ListPrice FROM QuoteLineItem];

        Test.startTest();
        QuoteLineItemTriggerHandler.calculateUnitPrice(qlis);
        Test.stopTest();
    }

    @isTest
    static void testStoreOldValuesAndUpdatePreviousValues() {
        // Retrieve the QuoteLineItem records to get the old values
        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>(
            [SELECT Id, Purchase_Price_in_INR__c, ListPrice FROM QuoteLineItem]
        );

        Test.startTest();
        QuoteLineItemTriggerHandler.storeOldValues(oldMap);
        Test.stopTest();

        // Retrieve a QuoteLineItem and update it
        QuoteLineItem qliToUpdate = [SELECT Id, Purchase_Price_in_INR__c, ListPrice FROM QuoteLineItem LIMIT 1];
        qliToUpdate.Purchase_Price_in_INR__c = 70;
        update qliToUpdate;

        // Retrieve the updated QuoteLineItem
        QuoteLineItem updatedQLI = [SELECT Previous_Purchase_Price__c, ListPrice FROM QuoteLineItem WHERE Id = :qliToUpdate.Id];

        // Optional: Assert that the Previous_Purchase_Price__c has been updated correctly
        System.assertEquals(60, updatedQLI.Previous_Purchase_Price__c, 'Previous_Purchase_Price__c should be updated to the old value.');
    }
}