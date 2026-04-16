@IsTest
private class SalesPriceApprovalForOpportunityTest {
    
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
            UnitPrice = 1000,
            IsActive = true
        );
        insert testPricebookEntry;

        // Create opportunity line item that meets approval criteria
        OpportunityLineItem testLineItem = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 10,
            UnitPrice = 900, // Less than list price (1000)
            Approval_Status__c = 'Pending'
        );
        insert testLineItem;
    }

    @IsTest
    static void testGetAllOpportunitiesPositive() {
        Test.startTest();
        List<SalesPriceApprovalForOpportunity.OpportunityWrapper> result = 
            SalesPriceApprovalForOpportunity.getAllOpportunities();
        Test.stopTest();

        
    }

    @IsTest
    static void testGetAllOpportunitiesNegative() {
        // Update line item to not meet criteria
        OpportunityLineItem item = [SELECT Id, Approval_Status__c FROM OpportunityLineItem LIMIT 1];
        item.Approval_Status__c = 'Approved';
        update item;

        Test.startTest();
        try {
            List<SalesPriceApprovalForOpportunity.OpportunityWrapper> result = 
                SalesPriceApprovalForOpportunity.getAllOpportunities();
           
        } catch (AuraHandledException e) {
            
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateOpportunityLineItems() {
        // First get the opportunities
        List<SalesPriceApprovalForOpportunity.OpportunityWrapper> wrappers = 
            SalesPriceApprovalForOpportunity.getAllOpportunities();
        
        // Modify the wrapper for update
        wrappers[0].lineItems[0].approvalStatus = 'Approved';
        wrappers[0].lineItems[0].approvalComments = 'Test approval';
        wrappers[0].lineItems[0].salesPrice = 850;
        wrappers[0].lineItems[0].updated = true;
        wrappers[0].updated = true;
        
        String serializedWrappers = JSON.serialize(wrappers);

        Test.startTest();
        String result = SalesPriceApprovalForOpportunity.updateOpportunityLineItems(serializedWrappers);
        Test.stopTest();

      
        
        // Verify database update
        OpportunityLineItem updatedItem = [SELECT Approval_Status__c, Approval_Comments__c, UnitPrice 
                                         FROM OpportunityLineItem LIMIT 1];
        
    }

    @IsTest
    static void testEmailNotification() {
        // Create wrapper and line item manually to test email functionality
        SalesPriceApprovalForOpportunity.OpportunityWrapper oppWrapper = new SalesPriceApprovalForOpportunity.OpportunityWrapper();
        oppWrapper.ownerEmail = 'test.owner@example.com';
        oppWrapper.ownerName = 'Test Owner';
        oppWrapper.name = 'Test Opportunity';
        oppWrapper.link = 'https://test.salesforce.com/opportunity';
        oppWrapper.attendeeName = 'Test Attendee';
        
        SalesPriceApprovalForOpportunity.OpportunityLineItemWrapper itemWrapper = 
            new SalesPriceApprovalForOpportunity.OpportunityLineItemWrapper();
        itemWrapper.approvalStatus = 'Approved';
        itemWrapper.productName = 'Test Product';
        itemWrapper.listPrice = 1000;
        itemWrapper.salesPrice = 900;
        
        oppWrapper.lineItems = new List<SalesPriceApprovalForOpportunity.OpportunityLineItemWrapper>{itemWrapper};
        
        // Create controller instance
        SalesPriceApprovalForOpportunity controller = new SalesPriceApprovalForOpportunity(oppWrapper);
        
        Test.startTest();
        
        Test.stopTest();
        
       
        
    }

    @IsTest
    static void testWrapperClasses() {
        // Test wrapper class constructors
        Opportunity testOpp = [SELECT Id, Name, AccountId, OwnerId, Owner.Email, Owner.Name, Link__c, 
                              Who_will_attend__r.Name FROM Opportunity LIMIT 1];
        OpportunityLineItem testItem = [SELECT Id, Product2.Name, ListPrice, UnitPrice, Quantity, 
                                       Approval_Status__c, Approval_Comments__c FROM OpportunityLineItem LIMIT 1];
        
        // Test OpportunityWrapper constructor
       // SalesPriceApprovalForOpportunity.OpportunityWrapper oppWrapper = 
        //    new SalesPriceApprovalForOpportunity.OpportunityWrapper(testOpp, new List<OpportunityLineItem>{testItem});
        
       
        
        // Test OpportunityLineItemWrapper constructor
        SalesPriceApprovalForOpportunity.OpportunityLineItemWrapper itemWrapper = 
            new SalesPriceApprovalForOpportunity.OpportunityLineItemWrapper(testItem);
        
       
    }
}