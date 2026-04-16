@isTest
public class AddQuoteLineItemTest {

    @testSetup
    static void setupData() {
        // Setup the necessary data for the test
        Profile p = [SELECT Id FROM Profile WHERE Name != 'Guest User' LIMIT 1];
        
        User testUser = new User(
            Alias = 'testusr', 
            Email = 'testuser11test@example.com', 
            EmailEncodingKey = 'UTF-8', 
            LastName = 'Test', 
            LanguageLocaleKey = 'en_US', 
            LocaleSidKey = 'en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'testuser1165test@example.com'
        );
        insert testUser;

        System.runAs(testUser) {
            // Create Account
            Account acc = new Account(Name = 'Test Account', OwnerId = testUser.Id);
            insert acc;

            // Create Pricebook
            Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
            update standardPricebook;

            // Create Product
            Product2 prod = new Product2(Name = 'Test Product', Family = 'Hardware', IsActive = true);
            insert prod;

            // Create PricebookEntry for the Product
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = standardPricebook.Id, 
                Product2Id = prod.Id, 
                UnitPrice = 100, 
                IsActive = true,
                CurrencyIsoCode = 'USD'
            );
            insert pbe;

            // Create Opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity', 
                AccountId = acc.Id, 
                CloseDate = Date.today(), 
                StageName = 'Prospecting'
            );
            insert opp;

            // Create Quote
            Quote quote = new Quote(
                Name = 'Test Quote',
                OpportunityId = opp.Id,
                Pricebook2Id = standardPricebook.Id,
                CurrencyIsoCode = 'USD'
            );
            insert quote;

            // Create Sample Request
            Sample_Out_Request__c sampleRequest = new Sample_Out_Request__c(
                Company_Name__c = acc.Id
            );
            insert sampleRequest;

            // Create Sample Out record to trigger the update on Opportunity Stage
            Sample_Out__c sampleOut = new Sample_Out__c(
                Sample_Out_Request__c = sampleRequest.Id,  
                Product_Name__c = prod.Id,
                Sample_Out_Status__c = 'Sample Approved',
                Quality__c = 'High Quality'
            );
            insert sampleOut;
        }
    }

    @isTest
    static void testCheckExistingQuote() {
        Quote quote = [SELECT Id, Name FROM Quote LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String result = AddQuoteLineItem.checkExistingQuote(quote.Name, acc.Id);
        Test.stopTest();
    }

    @isTest
    static void testAddQuoteLineItems_Success() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        String jsonLineItems = '[{"prodId": "' + prod.Id + '", "quality": "High", "volume": "10", "packaging": "1kg", "CommissionType": "Value", "commissionval": "5", "commissionper": "0", "price": "120", "freightval": "15"}]';
        
        Test.startTest();
        try {
            String result = AddQuoteLineItem.addQuoteLineItems(quote.Id, jsonLineItems);
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddQuoteLineItems_EmptyQuoteId() {
        Test.startTest();
        try {
            AddQuoteLineItem.addQuoteLineItems(null, '[{"prodId": "001", "volume": "10"}]');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddQuoteLineItems_EmptyJson() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        try {
            AddQuoteLineItem.addQuoteLineItems(quote.Id, '');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddQuoteLineItems_InvalidJsonFormat() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        try {
            AddQuoteLineItem.addQuoteLineItems(quote.Id, '{"prodId": "001", "volume": "10"}');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddQuoteLineItems_MissingProductId() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        try {
            AddQuoteLineItem.addQuoteLineItems(quote.Id, '[{"volume": "10"}]');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddQuoteLineItems_InvalidProductId() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        try {
            AddQuoteLineItem.addQuoteLineItems(quote.Id, '[{"prodId": "invalidId", "volume": "10"}]');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddQuoteLineItems_EmptyArray() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        try {
            AddQuoteLineItem.addQuoteLineItems(quote.Id, '[]');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddQuoteLineItems_InvalidCommissionValues() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        String jsonLineItems = '[{"prodId": "' + prod.Id + '", "quality": "High", "volume": "10", "packaging": "Box", "CommissionType": "Fixed", "commissionval": "invalid", "commissionper": "invalid", "price": "120", "freightval": "15"}]';
        
        Test.startTest();
        try {
            String result = AddQuoteLineItem.addQuoteLineItems(quote.Id, jsonLineItems);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddQuoteLineItems_NoPricebookEntry() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = new Product2(Name = 'New Product', IsActive = true);
        insert prod;
        
        String jsonLineItems = '[{"prodId": "' + prod.Id + '", "quality": "High", "volume": "10"}]';
        
        Test.startTest();
        try {
            AddQuoteLineItem.addQuoteLineItems(quote.Id, jsonLineItems);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddQuoteLineItems_WithStandardPricebook() {
        Quote quote = [SELECT Id, Pricebook2Id FROM Quote LIMIT 1];
        quote.Pricebook2Id = null; 
        update quote;
        
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        String jsonLineItems = '[{"prodId": "' + prod.Id + '", "quality": "High", "volume": "10"}]';
        
        Test.startTest();
        try {
            String result = AddQuoteLineItem.addQuoteLineItems(quote.Id, jsonLineItems);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetQualityForProductFromQuote_Success() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        Test.startTest();
        String result = AddQuoteLineItem.getQualityForProductFromQuote(quote.Id, prod.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetQualityForProductFromQuote_NoSampleFound() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Product2 prod = new Product2(Name = 'New Product', IsActive = true);
        insert prod;

        Test.startTest();
        String result = AddQuoteLineItem.getQualityForProductFromQuote(quote.Id, prod.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetQuoteData() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        Quote result = AddQuoteLineItem.getQuoteData(quote.Id);
        Test.stopTest();
    }

    @isTest
    static void testFetchAccountIdFromQuote() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        String result = AddQuoteLineItem.fetchAccountIdFromQuote(quote.Id);
        Test.stopTest();
    }

    @isTest
    static void testFindRecentPricesForQuote() {
        Quote quote = [SELECT Id, AccountId FROM Quote LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        Test.startTest();
        List<QuoteLineItem> result = AddQuoteLineItem.findRecentPricesForQuote(quote.AccountId, prod.Id);
        Test.stopTest();
    }

    @isTest
    static void testFetchQuoteData() {
        Quote quote = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        Quote result = AddQuoteLineItem.fetchQuoteData(quote.Id);
        Test.stopTest();
    }
}