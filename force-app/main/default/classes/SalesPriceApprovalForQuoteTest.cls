@IsTest
private class SalesPriceApprovalForQuoteTest {
    @TestSetup
    static void setup() {
        // Create test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        Contact con = new Contact(LastName = 'Test Attendee', Email = 'attendee@test.com');
        insert con;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
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
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebook.Id,
            Who_will_attend__c = testUser.Id
            
        );
        insert q;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 90, // Less than ListPrice to trigger approval
            Approval_Status__c = 'Pending'
        );
        insert qli;
    }

    @IsTest
    static void testGetAllQuotesPositive() {
        Test.startTest();
        List<SalesPriceApprovalForQuote.QuoteWrapper> wrappers = SalesPriceApprovalForQuote.getAllQuotes();
        Test.stopTest();

      
    }

    @IsTest
    static void testGetAllQuotesNegative() {
        // Update QLI to not meet criteria
        QuoteLineItem qli = [SELECT Id, UnitPrice FROM QuoteLineItem LIMIT 1];
        qli.UnitPrice = 100; // Equal to ListPrice
        update qli;

        Test.startTest();
        try {
            List<SalesPriceApprovalForQuote.QuoteWrapper> wrappers = SalesPriceApprovalForQuote.getAllQuotes();
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateQuoteLineItems() {
        List<SalesPriceApprovalForQuote.QuoteWrapper> wrappers = SalesPriceApprovalForQuote.getAllQuotes();
        wrappers[0].lineItems[0].approvalStatus = 'Approved';
        wrappers[0].lineItems[0].updated = true;
        wrappers[0].updated = true;
        String serializedWrappers = JSON.serialize(wrappers);

        Test.startTest();
        String result = SalesPriceApprovalForQuote.updateQuoteLineItems(serializedWrappers);
        Test.stopTest();

       
        QuoteLineItem updatedQli = [SELECT Approval_Status__c FROM QuoteLineItem LIMIT 1];
    }

    @IsTest
    static void testEmailNotification() {
        // Prepare wrapper and line item
        SalesPriceApprovalForQuote.QuoteWrapper qw = new SalesPriceApprovalForQuote.QuoteWrapper();
        qw.ownerEmail = 'test@owner.com';
        qw.ownerName = 'Test Owner';
        qw.name = 'Test Quote';
        qw.link = 'https://test.com';
        qw.attendeeName = 'Test Attendee';

        SalesPriceApprovalForQuote.QuoteLineItemWrapper item = new SalesPriceApprovalForQuote.QuoteLineItemWrapper();
        item.approvalStatus = 'Approved';
        item.productName = 'Test Product';
        item.listPrice = 100;
        item.salesPrice = 90;
        qw.lineItems = new List<SalesPriceApprovalForQuote.QuoteLineItemWrapper>{ item };

        SalesPriceApprovalForQuote app = new SalesPriceApprovalForQuote(qw);

        Test.startTest();
       
        Test.stopTest();

        
    }
}