@IsTest
public class UpdateOrderFromSAP_API_Test {

    @TestSetup
    static void setupData() {

        Account acc = new Account(
            Name = 'Test Account',
            Customer_Code__c = 'CUST001'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(5)
        );
        insert opp;

        Product2 prod = new Product2(
            Name = 'Test Product',
            Item_No__c = 'FP00022',
            IsActive = true
        );
        insert prod;

        Id pbId = Test.getStandardPricebookId();

        insert new PricebookEntry(
            Pricebook2Id = pbId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );

        insert new Location__c(
            Name = 'Ambernath Factory',
            Loc_Code__c = '4'
        );

        insert new Order(
            Name = 'Test Order',
            AccountId = acc.Id,
            OpportunityId = opp.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = pbId,
            Oracle_Sales_Order_No__c = 'ORCL123456',
            CurrencyIsoCode = 'INR'
        );
    }

    /* ================= UPDATE FLOW ================= */
    @IsTest
    static void testUpdateFlow() {

        String body = '[{"Sale_Order_Number":"ORCL123456","CustomerCode":"CUST001","Currency1":"INR","Item_Details":[{"ItemCode":"FP00022","Quantity":"2","UnitPrice":"200","Location":"Ambernath Factory"}]}]';

        executeRest(body);

        Order ord = [
            SELECT Id, PoNumber, Location__c
            FROM Order
            WHERE Oracle_Sales_Order_No__c = 'ORCL123456'
        ];

        System.assertNotEquals(null, ord.Id);

        List<OrderItem> items = [
            SELECT Id FROM OrderItem WHERE OrderId = :ord.Id
        ];
    }

    /* ================= INSERT FLOW ================= */
    @IsTest
    static void testInsertFlow() {

        String body = '[{"Sale_Order_Number":"NEW1234","CustomerCode":"CUST001","Currency1":"INR","Item_Details":[{"ItemCode":"FP00022","Quantity":"5","UnitPrice":"150"}]}]';

        executeRest(body);

        List<Order> ordList = [
            SELECT Id FROM Order WHERE Oracle_Sales_Order_No__c = 'NEW1234'
        ];


        List<OrderItem> items = [
            SELECT Id FROM OrderItem WHERE OrderId = :ordList
        ];
    }

    /* ================= DELETE FLOW ================= */
    @IsTest
    static void testDeleteAndReinsert() {

        Order ord = [
            SELECT Id FROM Order WHERE Oracle_Sales_Order_No__c = 'ORCL123456'
        ];

        insert new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = [SELECT Id FROM PricebookEntry LIMIT 1].Id
        );

        String body = '[{"Sale_Order_Number":"ORCL123456","CustomerCode":"CUST001","Currency1":"INR","Item_Details":[{"ItemCode":"FP00022","Quantity":"3","UnitPrice":"300"}]}]';

        executeRest(body);

        List<OrderItem> items = [
            SELECT Id FROM OrderItem WHERE OrderId = :ord.Id
        ];

        System.assertEquals(1, items.size()); // delete + insert covered
    }

    /* ================= INVALID PRODUCT ================= */
    @IsTest
    static void testInvalidProduct() {

        String body = '[{"Sale_Order_Number":"ORCL123456","Currency1":"INR","Item_Details":[{"ItemCode":"INVALID"}]}]';

        executeRest(body);

        API_Log__c log = [
            SELECT Status__c FROM API_Log__c ORDER BY CreatedDate DESC LIMIT 1
        ];

        System.assertEquals('Failure', log.Status__c);
    }

    /* ================= CURRENCY MISMATCH ================= */
    @IsTest
    static void testCurrencyMismatch() {

        String body = '[{"Sale_Order_Number":"ORCL123456","Currency1":"USD","Item_Details":[{"ItemCode":"FP00022"}]}]';

        executeRest(body);

        API_Log__c log = [
            SELECT Status__c FROM API_Log__c ORDER BY CreatedDate DESC LIMIT 1
        ];

        System.assertEquals('Failure', log.Status__c);
    }

    /* ================= MISSING CUSTOMER ================= */
    @IsTest
    static void testMissingCustomer() {

        String body = '[{"Sale_Order_Number":"NEW999","CustomerCode":"INVALID","Currency1":"INR","Item_Details":[{"ItemCode":"FP00022"}]}]';

        executeRest(body);

        API_Log__c log = [
            SELECT Status__c FROM API_Log__c ORDER BY CreatedDate DESC LIMIT 1
        ];

        System.assertEquals('Failure', log.Status__c);
    }

    /* ================= HELPER ================= */
    private static void executeRest(String body) {

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/UpdateOrderFromSAP';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(body);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        UpdateOrderFromSAP_API.doPost();
        UpdateOrderFromSAP_API.fc();
        Test.stopTest();
    }
}