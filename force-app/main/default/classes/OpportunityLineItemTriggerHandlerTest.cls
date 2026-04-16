@isTest
public class OpportunityLineItemTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // Create test Product2
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        // Create Pricebook
        Pricebook2 StandardPricebook= new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update StandardPricebook;

        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = StandardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 0,
            IsActive = true
        );
        insert pbe;

        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 0
        );
        insert oli;
    }

    @isTest
    static void testCalculateUnitPrice() {
        // Fetch OpportunityLineItems
        List<OpportunityLineItem> oliList = [SELECT Id, UnitPrice, ListPrice,Quantity, Converted_Purchase_Price__c, Margin_Amount__c FROM OpportunityLineItem];
        
        // Ensure proper isolation with startTest and stopTest
        Test.startTest();
        OpportunityLineItemTriggerHandler.calculateUnitPrice(oliList);
        Test.stopTest();
    }

    @isTest
    static void testStoreOldValues() {
        // Fetch OpportunityLineItems
        Map<Id, OpportunityLineItem> oldMap = new Map<Id, OpportunityLineItem>([SELECT Id, Purchase_Price_in_INR__c FROM OpportunityLineItem]);
        
        // Ensure proper isolation with startTest and stopTest
        Test.startTest();
        OpportunityLineItemTriggerHandler.storeOldValues(oldMap);
        Test.stopTest();       
    }

    @isTest
    static void testUpdatePreviousValues() {
        // Fetch OpportunityLineItems
        List<OpportunityLineItem> oliList = [SELECT Id, Purchase_Price_in_INR__c FROM OpportunityLineItem];
        
        // Update first OpportunityLineItem to change its value
        oliList[0].Purchase_Price_in_INR__c = 70;
        update oliList;
        
        // Fetch updated OpportunityLineItem to verify changes
        Map<Id, OpportunityLineItem> newMap = new Map<Id, OpportunityLineItem>([SELECT Id, Purchase_Price_in_INR__c FROM OpportunityLineItem]);

        // Ensure proper isolation with startTest and stopTest
        Test.startTest();
        OpportunityLineItemTriggerHandler.updatePreviousValues(newMap);
        Test.stopTest();
        
        // Verify the Previous Purchase Price
        OpportunityLineItem updatedOli = [SELECT Previous_Purchase_Price__c FROM OpportunityLineItem WHERE Id = :oliList[0].Id];
       // System.assertNotEquals(null, updatedOli.Previous_Purchase_Price__c, 'The Previous_Purchase_Price__c should be updated.');
    }
}