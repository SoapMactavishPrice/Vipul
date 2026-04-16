@isTest
public class OpportunityLineItemTriggerTest {
    
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

        // Create a test Product2
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        // Create a test PricebookEntry
        Pricebook2 standardPricebook = new Pricebook2(
            Id= Test.getstandardPricebookId(),
            IsActive=True);
        update standardPricebook;

        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = standardPricebook.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;

        // Create an OpportunityLineItem record
        OpportunityLineItem testOLI = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 1,
            TotalPrice = 100
        );
        insert testOLI;
    }
    
    @isTest
    static void testBeforeInsertTrigger() {
        // Fetch test Opportunity and PricebookEntry
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry testPricebookEntry = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create a new OpportunityLineItem
        OpportunityLineItem newOLI = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 2,
            TotalPrice = 200
        );

        Test.startTest();
        insert newOLI;
        Test.stopTest();

        // Retrieve inserted OpportunityLineItem
        OpportunityLineItem insertedOLI = [SELECT Id, Quantity, TotalPrice FROM OpportunityLineItem WHERE Id = :newOLI.Id LIMIT 1];

    }

    @isTest
    static void testBeforeUpdateTrigger() {
        // Fetch test OpportunityLineItem
        OpportunityLineItem testOLI = [SELECT Id, Quantity, TotalPrice FROM OpportunityLineItem LIMIT 1];

        // Update the Quantity
        testOLI.Quantity = 3;

        Test.startTest();
        update testOLI;
        Test.stopTest();

        // Retrieve updated OpportunityLineItem
        OpportunityLineItem updatedOLI = [SELECT Id, Quantity FROM OpportunityLineItem WHERE Id = :testOLI.Id LIMIT 1];

    }

    @isTest
    static void testAfterUpdateTrigger() {
        // Fetch test OpportunityLineItem
        OpportunityLineItem testOLI = [SELECT Id, Quantity, TotalPrice FROM OpportunityLineItem LIMIT 1];

        // Update the Total Price
        testOLI.TotalPrice = 250;

        Test.startTest();
        update testOLI;
        Test.stopTest();

        // Retrieve updated OpportunityLineItem
        OpportunityLineItem updatedOLI = [SELECT Id, TotalPrice FROM OpportunityLineItem WHERE Id = :testOLI.Id LIMIT 1];

    }
}