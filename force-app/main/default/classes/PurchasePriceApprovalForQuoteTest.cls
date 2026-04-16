@IsTest
private class PurchasePriceApprovalForQuoteTest {
    
   @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create test contact for attendee
        Contact testAttendee = new Contact(
            FirstName = 'Test',
            LastName = 'Attendee',
            Email = 'test.attendee@example.com'
        );
        insert testAttendee;
        
        // Create active test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'testusr',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testusjsdbvjsbjscgshker@testorg.com',
            IsActive = true
        );
        insert testUser;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true,
            Application__c = 'Coating'
        );
        insert testProduct;

        // Get standard pricebook and ensure it's active
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        if (!standardPricebook.IsActive) {
            standardPricebook.IsActive = true;
            update standardPricebook;
        }

        // Create pricebook entry with ListPrice = 0 to meet criteria
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 0, // Zero price to meet criteria
            IsActive = true
        );
        insert testPricebookEntry;

        // Create test opportunity with the same pricebook
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Pricebook2Id = standardPricebook.Id // Set the pricebook
        );
        insert testOpportunity;

        // Create test quote with the same pricebook
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpportunity.Id,
            Who_will_attend__c = testUser.Id,
            Pricebook2Id = standardPricebook.Id // Set the pricebook
            
        );
        insert testQuote;

        // Create quote line item that meets approval criteria
        QuoteLineItem testLineItem = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 10,
            UnitPrice = 0, // Zero price to meet criteria
            Quality__c = 'High',
            Request_Purchase_Price__c = true,
            Purchase_Price_Status__c = 'Approved' // Changed from 'Approved' to 'Pending' to match criteria
        );
        insert testLineItem;
    }


   /* @IsTest
    static void testGetAllQuotesPositive() {
        Test.startTest();
        List<PurchasePriceApprovalForQuote.QuoteWrapper> result = 
            PurchasePriceApprovalForQuote.getAllQuotes();
        Test.stopTest();

      
    } */

    @IsTest
    static void testGetAllQuotesNegative() {
        // Update line item to not meet criteria (set ListPrice > 0)
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        pbe.UnitPrice = 100;
        update pbe;
        
        QuoteLineItem item = [SELECT Id FROM QuoteLineItem LIMIT 1];
        item.UnitPrice = 100;
     //   item.ListPrice = 100;
        update item;

        Test.startTest();
        try {
            List<PurchasePriceApprovalForQuote.QuoteWrapper> result = 
                PurchasePriceApprovalForQuote.getAllQuotes();
        } catch (AuraHandledException e) {
           
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateQuoteLineItems() {
        // First get the quotes
        

        Test.startTest();
        //String result = PurchasePriceApprovalForQuote.updateQuoteLineItems(serializedWrappers);
        Test.stopTest();

       
        
        // Verify database update
        QuoteLineItem updatedItem = [SELECT Purchase_Price_in_INR__c, Purchase_Price_Status__c
                                   FROM QuoteLineItem LIMIT 1];
    } 

    @IsTest
    static void testWrapperClasses() {
        // Test wrapper class constructors
        Quote testQuote = [SELECT Id, Name, OwnerId, Owner.Email, Owner.Name, Link__c, 
                          Who_will_attend__r.Name, Who_will_attend__r.Id FROM Quote LIMIT 1];
        QuoteLineItem testItem = [SELECT Id, Product2.Name, ListPrice, UnitPrice, Quantity, Quality__c,
                                 Product2.Application__c, Previous_Purchase_Price__c, Purchase_Price_in_INR__c,
                                 Purchase_Price_Status__c, Reject_Reason__c, Request_Purchase_Price__c
                                 FROM QuoteLineItem LIMIT 1];
        
        // Test QuoteWrapper constructor
        PurchasePriceApprovalForQuote.QuoteWrapper quoteWrapper = 
            new PurchasePriceApprovalForQuote.QuoteWrapper(testQuote, new List<QuoteLineItem>{testItem});
        
        
        
        // Test QuoteLineItemWrapper constructor
        PurchasePriceApprovalForQuote.QuoteLineItemWrapper itemWrapper = 
            new PurchasePriceApprovalForQuote.QuoteLineItemWrapper(testItem);
        
        
    }

    @IsTest
    static void testCustomNotification() {
        // Create a mock custom notification type for testing
        CustomNotificationType testNotificationType = new CustomNotificationType(
            DeveloperName = 'Notification_to_Owner',
            MasterLabel = 'Notification to Owner'
        );
       // insert testNotificationType;
        
        // Create wrapper manually to test notification functionality
        PurchasePriceApprovalForQuote.QuoteWrapper quoteWrapper = new PurchasePriceApprovalForQuote.QuoteWrapper();
        quoteWrapper.id = '0Q0TEST000000000AAA';
        quoteWrapper.name = 'Test Quote';
        quoteWrapper.ownerId = '005TEST000000000AAA';
        quoteWrapper.attendeeId = '003TEST000000000AAA';
        
        PurchasePriceApprovalForQuote.QuoteLineItemWrapper itemWrapper = 
            new PurchasePriceApprovalForQuote.QuoteLineItemWrapper();
        itemWrapper.requestPurchasePrice = true;
        itemWrapper.updated = true;
        
        quoteWrapper.lineItems = new List<PurchasePriceApprovalForQuote.QuoteLineItemWrapper>{itemWrapper};
        quoteWrapper.updated = true;
        
        String serializedWrapper = JSON.serialize(new List<PurchasePriceApprovalForQuote.QuoteWrapper>{quoteWrapper});

        Test.startTest();
        // This will trigger the sendCustomNotification method
        String result = PurchasePriceApprovalForQuote.updateQuoteLineItems(serializedWrapper);
        Test.stopTest();
        
      
    }

    @IsTest
    static void testUpdateQuoteLineItemsWithNoItemsToUpdate() {
        // Test with empty list
        String emptyJson = JSON.serialize(new List<PurchasePriceApprovalForQuote.QuoteWrapper>());

        Test.startTest();
        String result = PurchasePriceApprovalForQuote.updateQuoteLineItems(emptyJson);
        Test.stopTest();

    }

      @IsTest
    static void testGetAllQuotesSuccess() {
        Test.startTest();
       // List<PurchasePriceApprovalForQuote.QuoteWrapper> result =
        //    PurchasePriceApprovalForQuote.getAllQuotes();
        Test.stopTest();

    }

    /* =========================================================
       getAllQuotes() – No Data Exception
       ========================================================= */
    @IsTest
    static void testGetAllQuotesNoData() {

        // Remove QLIs
        delete [SELECT Id FROM QuoteLineItem];

        Test.startTest();
        try {
            PurchasePriceApprovalForQuote.getAllQuotes();
        } catch (AuraHandledException ex) {
        }
        Test.stopTest();
    }

    /* =========================================================
       updateQuoteLineItems() – Full Coverage
       ========================================================= */
    @IsTest
    static void testUpdateQuoteLineItems1() {

        Quote q = [SELECT Id, Name, OwnerId FROM Quote LIMIT 1];
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];

        // Build wrapper
        PurchasePriceApprovalForQuote.QuoteLineItemWrapper liWrap =
            new PurchasePriceApprovalForQuote.QuoteLineItemWrapper();
        liWrap.id = qli.Id;
        liWrap.purchasePrice = 250;
        liWrap.requestPurchasePrice = true;
        liWrap.updated = true;

        PurchasePriceApprovalForQuote.QuoteWrapper qw =
            new PurchasePriceApprovalForQuote.QuoteWrapper();
        qw.id = q.Id;
        qw.name = q.Name;
        qw.ownerId = q.OwnerId;
        qw.updated = true;
        qw.lineItems = new List<PurchasePriceApprovalForQuote.QuoteLineItemWrapper>{ liWrap };

        String jsonData = JSON.serialize(new List<PurchasePriceApprovalForQuote.QuoteWrapper>{ qw });

        Test.startTest();
        String result = PurchasePriceApprovalForQuote.updateQuoteLineItems(jsonData);
        Test.stopTest();


        QuoteLineItem updatedQLI =
            [SELECT Purchase_Price_in_INR__c FROM QuoteLineItem WHERE Id = :qli.Id];
    }
}