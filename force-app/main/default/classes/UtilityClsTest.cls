@isTest
private class UtilityClsTest {

    @TestSetup
    static void setupTestData() {
        // Use the standard pricebook for creating PricebookEntry
        Id standardPricebookId = Test.getStandardPricebookId();

        Pricebook2 testPricebook = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert testPricebook;
        
        // Create an Account
        Account testAccount = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD', INCO_Terms__c = 'DDP');
        insert testAccount;
        
        // Create an Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today().addDays(10),
            StageName = 'Prospecting',
            Pricebook2Id = testPricebook.Id,
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        
        // Create a Product
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;
        
        // Create a PricebookEntry for the Product in the standard pricebook
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId, // Standard Pricebook
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPricebookEntry;
        
        // Create a PricebookEntry for the Product in the custom pricebook
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = testPricebook.Id, // Custom Pricebook
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;
        
        // Create an OpportunityLineItem for the Opportunity
        OpportunityLineItem testOLI = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOLI;
    }

    @isTest
    static void testGetAllFields() {
        Map<String, String> result = UtilityCls.getAllFields('Opportunity');
    }

    @isTest
    static void testQuery() {
        List<SObject> objList = [SELECT Id FROM Opportunity LIMIT 1];
        Schema.DescribeFieldResult dfr = Opportunity.Id.getDescribe();
        Map<String, String> result = UtilityCls.query(objList, dfr);
    }

    @isTest
    static void testGetPriceList() {
        Map<String, Pricebook2> result = UtilityCls.getPriceList();
    }

    @isTest
    static void testGetDateFormate() {
        Date result = UtilityCls.getDateFormate('20210403');
    }
}