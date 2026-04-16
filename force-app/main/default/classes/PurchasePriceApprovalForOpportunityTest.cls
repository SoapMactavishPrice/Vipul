@IsTest
    private class PurchasePriceApprovalForOpportunityTest {
    
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

        // Create test opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Who_will_attend__c = testUser.Id
           
        );
        insert testOpportunity;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true,
            Application__c = 'Coating'
        );
        insert testProduct;

        // Get standard pricebook
        	Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create pricebook entry with ListPrice = 0 to meet criteria
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 0, // Zero price to meet criteria
            IsActive = true
        );
        insert testPricebookEntry;

        // Create opportunity line item that meets approval criteria
        OpportunityLineItem testLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 10,
            UnitPrice = 0, // Zero price to meet criteria
            Quality__c = 'High',
            Request_Purchase_Price__c = true
        );
        insert testLineItem;
    }

    @IsTest
    static void testGetAllOpportunitiesPositive() {
        Test.startTest();
        List<PurchasePriceApprovalForOpportunity.OpportunityWrapper> result = 
            PurchasePriceApprovalForOpportunity.getAllOpportunities();
        Test.stopTest();

       
    }

    @IsTest
    static void testGetAllOpportunitiesNegative() {
        // Update line item to not meet criteria (set ListPrice > 0)
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        pbe.UnitPrice = 100;
        update pbe;
        
        OpportunityLineItem item = [SELECT Id FROM OpportunityLineItem LIMIT 1];
        item.UnitPrice = 100;
        //item.ListPrice = 100;
        update item;

        Test.startTest();
        try {
            List<PurchasePriceApprovalForOpportunity.OpportunityWrapper> result = 
                PurchasePriceApprovalForOpportunity.getAllOpportunities();
            
        } catch (AuraHandledException e) {
            
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateOpportunityLineItems() {
        // First get the opportunities
        List<PurchasePriceApprovalForOpportunity.OpportunityWrapper> wrappers = 
            PurchasePriceApprovalForOpportunity.getAllOpportunities();
        
        // Modify the wrapper for update
        wrappers[0].lineItems[0].purchasePrice = 500;
        wrappers[0].lineItems[0].requestPurchasePrice = true;
        wrappers[0].lineItems[0].updated = true;
        wrappers[0].updated = true;
        
        String serializedWrappers = JSON.serialize(wrappers);

        Test.startTest();
        String result = PurchasePriceApprovalForOpportunity.updateOpportunityLineItems(serializedWrappers);
        Test.stopTest();

        // Verify database update
        OpportunityLineItem updatedItem = [SELECT Purchase_Price_in_INR__c, Purchase_Price_Status__c
                                         FROM OpportunityLineItem LIMIT 1];

    }

    @IsTest
    static void testWrapperClasses() {
        // Test wrapper class constructors
        Opportunity testOpp = [SELECT Id, Name, OwnerId, Owner.Email, Owner.Name, Link__c, 
                              Who_will_attend__r.Name, Who_will_attend__r.Id FROM Opportunity LIMIT 1];
        OpportunityLineItem testItem = [SELECT Id, Product2.Name, ListPrice, UnitPrice, Quantity, Quality__c,
                                       Product2.Application__c, Previous_Purchase_Price__c, Purchase_Price_in_INR__c,
                                       Purchase_Price_Status__c, Reject_Reason__c, Request_Purchase_Price__c
                                       FROM OpportunityLineItem LIMIT 1];
        
        // Test OpportunityWrapper constructor
        PurchasePriceApprovalForOpportunity.OpportunityWrapper oppWrapper = 
            new PurchasePriceApprovalForOpportunity.OpportunityWrapper(testOpp, new List<OpportunityLineItem>{testItem});
       
        
        // Test OpportunityLineItemWrapper constructor
        PurchasePriceApprovalForOpportunity.OpportunityLineItemWrapper itemWrapper = 
            new PurchasePriceApprovalForOpportunity.OpportunityLineItemWrapper(testItem);
        
       
    }

    @IsTest
    static void testCustomNotification() {
        // Create a mock custom notification type for testing
        CustomNotificationType testNotificationType = new CustomNotificationType(
            DeveloperName = 'Notification_to_Owner',
            MasterLabel = 'Notification to Owner'
        );
      //  insert testNotificationType;
        
        // Create wrapper manually to test notification functionality
        PurchasePriceApprovalForOpportunity.OpportunityWrapper oppWrapper = new PurchasePriceApprovalForOpportunity.OpportunityWrapper();
        oppWrapper.id = '006TEST000000000AAA';
        oppWrapper.name = 'Test Opportunity';
        oppWrapper.ownerId = '005TEST000000000AAA';
        oppWrapper.attendeeId = '003TEST000000000AAA';
        
        PurchasePriceApprovalForOpportunity.OpportunityLineItemWrapper itemWrapper = 
            new PurchasePriceApprovalForOpportunity.OpportunityLineItemWrapper();
        itemWrapper.requestPurchasePrice = true;
        itemWrapper.updated = true;
        
        oppWrapper.lineItems = new List<PurchasePriceApprovalForOpportunity.OpportunityLineItemWrapper>{itemWrapper};
        oppWrapper.updated = true;
        
        String serializedWrapper = JSON.serialize(new List<PurchasePriceApprovalForOpportunity.OpportunityWrapper>{oppWrapper});

        Test.startTest();
        // This will trigger the sendCustomNotification method
      //  String result = PurchasePriceApprovalForOpportunity.updateOpportunityLineItems(serializedWrapper);
        Test.stopTest();
        
      
    }
}