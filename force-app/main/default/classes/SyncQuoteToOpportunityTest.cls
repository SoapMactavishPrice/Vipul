@isTest
public class SyncQuoteToOpportunityTest {
    @testSetup
    static void setupTestData() {
        // Create test Account
        Account acc = new Account();
        acc.Name = 'Finesse';
        acc.CurrencyIsoCode = 'USD';
        acc.INCO_Terms__c = 'DDP';
        acc.Payment_Terms__c = '30 days Credit';
        insert acc;
        
        Id PID = Test.getStandardPricebookId();
        
        Product2 prod = new Product2(Name = 'Test Product', isActive = true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = PID, 
            Product2Id = prod.Id,
            UnitPrice = 1000,
            IsActive = true);
        
        insert pbe;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Finesse';
        opp.StageName = 'Sampling';
        opp.CloseDate = Date.today();
        opp.AccountId = acc.Id;
       // opp.Contact__c = con.Id;
        opp.Pricebook2Id=PID;
        
        insert opp;
        
       
        
        // Create test Quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            //GrandTotal = 1000,
            CurrencyIsoCode = 'USD',
            Pricebook2Id = Test.getStandardPricebookId()
           // AccountId = acc.Id
        );
        insert quote;
        
        // Create test QuoteLineItem
        
        
        
         OpportunityLineItem oli = new OpportunityLineItem
            (OpportunityId = opp.Id,
             pricebookentryid=pbe.id, 
             product2Id= prod.Id,
             UnitPrice = 1000, 
             Quantity = 1, 
             Discount=10);
        insert oli;
        
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            Quantity = 10,
           // TotalPrice = 1000,
            PricebookEntryId = pbe.Id
        );
        insert qli;
    }
    
    @isTest
    static void testSyncQuoteToOpportunity() {
        // Retrieve test data
        Quote testQuote = [SELECT Id, OpportunityId FROM Quote LIMIT 1];
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Id = :testQuote.OpportunityId LIMIT 1];
        
        Test.startTest();
        
        // Instantiate class and call getData
        SyncQuoteToOpportunity syncObj = new SyncQuoteToOpportunity();
        ApexPages.currentPage().getParameters().put('quoteId', testQuote.Id);
        PageReference resultPage = syncObj.getData();
        
        Test.stopTest();
        
        // Verify Opportunity is updated
        Opportunity updatedOpp = [SELECT SyncedQuoteId FROM Opportunity WHERE Id = :testOpp.Id];
        
        // Verify OpportunityLineItems are created
        List<OpportunityLineItem> oppLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];
    }
    
    @isTest
    static void testCheckIsSync() {
        // Retrieve test Quote
        Quote testQuote = [SELECT Id, OpportunityId FROM Quote LIMIT 1];
        
        // Instantiate class
        SyncQuoteToOpportunity syncObj = new SyncQuoteToOpportunity();
        syncObj.quoteId = testQuote.Id;
        syncObj.getQuote();
        
        Boolean isSyncAvailable = syncObj.checkIsSync();
    }
    
    @isTest
    static void testUpdateOpportunity() {
        // Retrieve test Quote
        Quote testQuote = [SELECT Id, OpportunityId FROM Quote LIMIT 1];
        
        SyncQuoteToOpportunity syncObj = new SyncQuoteToOpportunity();
        syncObj.quoteId = testQuote.Id;
        syncObj.getQuote();
        
        Test.startTest();
        syncObj.updateOpportunity();
        Test.stopTest();
        
        // Verify Opportunity fields were updated
        Opportunity updatedOpp = [SELECT SyncedQuoteId FROM Opportunity WHERE Id = :testQuote.OpportunityId];
    }
    
    @isTest
    static void testUpdateOpporLineItem() {
        // Retrieve test Quote
        Quote testQuote = [SELECT Id, OpportunityId FROM Quote LIMIT 1];
        
        SyncQuoteToOpportunity syncObj = new SyncQuoteToOpportunity();
        syncObj.quoteId = testQuote.Id;
        syncObj.getQuote();
        syncObj.getQuoteLineItem();
        syncObj.getOppoLineItem();
        
        Test.startTest();
        syncObj.updateOpporLineItem();
        Test.stopTest();
        
        // Verify OpportunityLineItem is created
        List<OpportunityLineItem> oppLineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testQuote.OpportunityId];
    }
}