@IsTest
private class SendPurchasePriceEmailAsyncTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create test opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
           
        );
        insert testOpportunity;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        // Get standard pricebook
       	Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create pricebook entry
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;

        // Create opportunity line item
        OpportunityLineItem testLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 10,
            UnitPrice = 90,
            Purchase_Price_in_INR__c = 500
        );
        insert testLineItem;
    }

    @IsTest
    static void testSendEmailAsync() {
        // Create wrapper data
        SendPurchasePriceEmailAsync.OpportunityWrapper oppWrapper = new SendPurchasePriceEmailAsync.OpportunityWrapper();
        oppWrapper.id = '006TEST000000000AAA';
        oppWrapper.name = 'Test Opportunity';
        oppWrapper.ownerEmail = 'test.owner@example.com';
        oppWrapper.ownerName = 'Test Owner';
        oppWrapper.link = 'https://test.salesforce.com/opportunity';
        oppWrapper.attendeeName = 'Test Attendee';
        
        SendPurchasePriceEmailAsync.OpportunityLineItemWrapper itemWrapper = 
            new SendPurchasePriceEmailAsync.OpportunityLineItemWrapper();
        itemWrapper.productName = 'Test Product';
        itemWrapper.quantity = 10;
        itemWrapper.purchasePrice = 500;
        
        oppWrapper.lineItems = new List<SendPurchasePriceEmailAsync.OpportunityLineItemWrapper>{itemWrapper};
        
        String serializedWrapper = JSON.serialize(oppWrapper);

        Test.startTest();
        // Call the future method
        SendPurchasePriceEmailAsync.sendEmailAsync(serializedWrapper);
        Test.stopTest();
        
       
    }

    @IsTest
    static void testSendEmailAsyncWithNullPurchasePrice() {
        // Create wrapper data with null purchase price
        SendPurchasePriceEmailAsync.OpportunityWrapper oppWrapper = new SendPurchasePriceEmailAsync.OpportunityWrapper();
        oppWrapper.id = '006TEST000000000AAA';
        oppWrapper.name = 'Test Opportunity';
        oppWrapper.ownerEmail = 'test.owner@example.com';
        oppWrapper.ownerName = 'Test Owner';
        oppWrapper.link = 'https://test.salesforce.com/opportunity';
        oppWrapper.attendeeName = 'Test Attendee';
        
        SendPurchasePriceEmailAsync.OpportunityLineItemWrapper itemWrapper = 
            new SendPurchasePriceEmailAsync.OpportunityLineItemWrapper();
        itemWrapper.productName = 'Test Product';
        itemWrapper.quantity = 10;
        itemWrapper.purchasePrice = null; // Null purchase price
        
        oppWrapper.lineItems = new List<SendPurchasePriceEmailAsync.OpportunityLineItemWrapper>{itemWrapper};
        
        String serializedWrapper = JSON.serialize(oppWrapper);

        Test.startTest();
        // Call the future method
        SendPurchasePriceEmailAsync.sendEmailAsync(serializedWrapper);
        Test.stopTest();
        

    }

    @IsTest
    static void testSendEmailAsyncWithNoAttendee() {
        // Create wrapper data with no attendee
        SendPurchasePriceEmailAsync.OpportunityWrapper oppWrapper = new SendPurchasePriceEmailAsync.OpportunityWrapper();
        oppWrapper.id = '006TEST000000000AAA';
        oppWrapper.name = 'Test Opportunity';
        oppWrapper.ownerEmail = 'test.owner@example.com';
        oppWrapper.ownerName = 'Test Owner';
        oppWrapper.link = 'https://test.salesforce.com/opportunity';
        oppWrapper.attendeeName = null; // No attendee
        
        SendPurchasePriceEmailAsync.OpportunityLineItemWrapper itemWrapper = 
            new SendPurchasePriceEmailAsync.OpportunityLineItemWrapper();
        itemWrapper.productName = 'Test Product';
        itemWrapper.quantity = 10;
        itemWrapper.purchasePrice = 500;
        
        oppWrapper.lineItems = new List<SendPurchasePriceEmailAsync.OpportunityLineItemWrapper>{itemWrapper};
        
        String serializedWrapper = JSON.serialize(oppWrapper);

        Test.startTest();
        // Call the future method
        SendPurchasePriceEmailAsync.sendEmailAsync(serializedWrapper);
        Test.stopTest();
        
       
    }

   
}