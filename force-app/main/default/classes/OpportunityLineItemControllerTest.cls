@isTest
private class OpportunityLineItemControllerTest {

    @TestSetup
    static void setupTestData() {
        // Step 1: Fetch the Standard Pricebook ID
        Id standardPricebookId = Test.getStandardPricebookId();

        // Step 2: Create a Product
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        // Step 3: Create a Standard PricebookEntry
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId, // Standard Pricebook
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPricebookEntry;

        // Step 4: Create a Custom Pricebook
        Pricebook2 testPricebook = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert testPricebook;

        // Step 5: Create a Custom PricebookEntry
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,  // Custom Pricebook
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;

        // Step 6: Create a Test Account record
        Account testAccount = new Account(Name = 'Test Account', CurrencyIsoCode = 'USD',INCO_Terms__c = 'DDP');
        insert testAccount;

        // Step 7: Create a Test Opportunity with an Owner
        User testUser = [SELECT Id, Email, Name FROM User WHERE Id = :UserInfo.getUserId()];
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            CloseDate = Date.today().addDays(10),
            StageName = 'Prospecting',
            Pricebook2Id = testPricebook.Id, // Make sure the Opportunity has a Pricebook
            Inco_Terms__c = 'DDP',
            OwnerId = testUser.Id, // Assign to test user
            AccountId = testAccount.Id // Associate with the Account
        );
        insert testOpportunity;

        // Step 8: Create an OpportunityLineItem
        OpportunityLineItem testOLI = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id, // Link to created Opportunity
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 100,
            Purchase_Price_in_INR__c = 1000,
            Margin_Type__c = 'Value',
            Margin_Value__c = 20,
            Commission_Type__c = 'Value',
            Commission_Value__c = 100,
            Freight_Value__c = 50,
            Purchase_Price_Status__c = 'Approved'
        );
        insert testOLI;

        // Create an Order with necessary data and Pricebook
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Pricebook2Id = testPricebook.Id,  // Set the Pricebook for the Order
            Status = 'Draft',
            EffectiveDate = Date.today()
        );
        insert testOrder;

        // Create OrderItem linked to the Order
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert testOrderItem;

        // Create a Quote
        Quote testQuote = new Quote(Name = 'Test Quote', OpportunityId = testOpportunity.Id);
        insert testQuote;

        // Create QuoteLineItem linked to Quote
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 10,
            UnitPrice = 100
        );
        insert qli;
    }

    @isTest
    static void testGetOpportunityLineItems() {
        Opportunity testOpportunity = [SELECT Id FROM Opportunity LIMIT 1];
        List<OpportunityLineItem> result = OpportunityLineItemController.getOpportunityLineItems(testOpportunity.Id);
        System.assertNotEquals(0, result.size(), 'Expected non-empty result from getOpportunityLineItems');
    }

    @isTest
    static void testUpdateOpportunityLineItems() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        oli.Quantity = 15;
        update oli;
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>{ oli };
        OpportunityLineItemController.updateOpportunityLineItems(lineItems);
    }

    @isTest
    static void testGetQuoteLineItems() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        List<QuoteLineItem> result = OpportunityLineItemController.getQuoteLineItems(testQuote.Id);
        System.assertNotEquals(0, result.size(), 'Expected non-empty result from getQuoteLineItems');
    }

    @isTest
    static void testUpdateQuoteLineItems() {
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        qli.Quantity = 15;
        update qli;
        List<QuoteLineItem> lineItems = new List<QuoteLineItem>{ qli };
        OpportunityLineItemController.updateQuoteLineItems(lineItems);
    }

    @isTest
    static void testGetOrderItems() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        List<OrderItem> result = OpportunityLineItemController.getOrderItems(testOrder.Id);
        System.assertNotEquals(0, result.size(), 'Expected non-empty result from getOrderItems');
    }

    @isTest
    static void testUpdateOrderItems() {
        OrderItem oi = [SELECT Id FROM OrderItem LIMIT 1];
        oi.Quantity = 15;
        update oi;
        List<OrderItem> lineItems = new List<OrderItem>{ oi };
        OpportunityLineItemController.updateOrderItems(lineItems);
    }
}