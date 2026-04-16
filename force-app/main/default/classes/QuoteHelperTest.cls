@isTest
public class QuoteHelperTest {
    @testSetup
    static void setup() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account', INCO_Terms__c = 'DDP');
        insert testAccount;

        Product2 testProduct = new Product2(Name = 'Test Product');
        insert testProduct;
        
        Id PID = Test.getStandardPricebookId();

       // Pricebook2 standardPricebook = PID;
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = PID,
            Product2Id = testProduct.Id,
            UnitPrice = 100.0,
            IsActive = true
        );
        insert testPricebookEntry;
        
        Contact con = new Contact();
        con.AccountId = testAccount.id;
        con.FirstName = 'Prashant';
        con.LastName = 'Padal';
        con.Email = 'Prashantpadal@finessedirect.com';
        con.Phone = '123-456-7890';
        con.CurrencyIsoCode = 'USD';
        insert con;
        
      
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Finesse';
        opp.StageName = 'Sampling';
        opp.CloseDate = Date.today();
        opp.AccountId = testAccount.Id;
        opp.Contact__c = con.Id;
        opp.Pricebook2Id=PID;
        
        insert opp;

        Quote testQuote = new Quote(
            Name = 'Test Quote',
           // AccountId = testAccount.Id,
            Pricebook2Id = PID,
            OpportunityId = opp.id
        );
        insert testQuote;

        QuoteLineItem testQuoteLineItem = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 10,
            UnitPrice = 100.0
        );
        insert testQuoteLineItem;

        Sample_Request__c testSampleRequest = new Sample_Request__c(
            Company_Name__c = testAccount.Id
        );
        insert testSampleRequest;

        Sample_Out__c testSampleOut = new Sample_Out__c(
            Sample_Request__c = testSampleRequest.Id,
            Product_Name__c = testProduct.Id,
            Quality__c = 'High'
        );
        insert testSampleOut;
    }

    @isTest
    static void testFindRecentPricesForQuote() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];

        List<QuoteLineItem> quoteLineItems = QuoteHelper.findRecentPricesForQuote(testAccount.Id, testProduct.Id);
    }

    @isTest
    static void testFetchQuoteData() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];

        Quote quote = QuoteHelper.fetchQuoteData(testQuote.Id);
    }

    @isTest
    static void testGetQualityForProductFromQuote() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];

        String quality = QuoteHelper.getQualityForProductFromQuote(testQuote.Id, testProduct.Id);
    }
}