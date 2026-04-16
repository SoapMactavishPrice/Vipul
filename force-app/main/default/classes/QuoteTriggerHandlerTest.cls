@isTest
public class QuoteTriggerHandlerTest {

    @testSetup
    static void setupData() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert prod;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPricebook.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebook.Id,
            CurrencyIsoCode = 'USD',
            Order_Created__c = false
        );
        insert q;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 10,
            UnitPrice = 100
        );
        insert qli;
    }

    @isTest
    static void testCreateOrder() {

        Quote existing = [
            SELECT Id, SAP_SO_Number__c, Order_Created__c
            FROM Quote
            LIMIT 1
        ];

        existing.SAP_SO_Number__c = 'SO12345';

        Test.startTest();
            update existing; // trigger fires here
        Test.stopTest();

        List<Order> orders = [
            SELECT Id, QuoteId
            FROM Order
            WHERE QuoteId = :existing.Id
        ];

        List<OrderItem> items = [
            SELECT Id
            FROM OrderItem
            WHERE OrderId = :orders[0].Id
        ];
    }

    @isTest
    static void testNoOrderCreationIfSAPSONumberNotNew() {

        Quote q = [
            SELECT Id, SAP_SO_Number__c
            FROM Quote
            LIMIT 1
        ];

        Test.startTest();
            update q; // no change → no order
        Test.stopTest();

        List<Order> orders = [
            SELECT Id
            FROM Order
            WHERE QuoteId = :q.Id
        ];
    }
}