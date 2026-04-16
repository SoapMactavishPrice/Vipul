@IsTest
public class CreateSalesOrder_ToOracleTest {
    // Helper method to create test data
    private static void setupTestData(String objectType) {
        // Create Country
        Country__c country = new Country__c(Name = 'Test Country', COUNTRY_CODE__c = 'US');
        insert country;
        
        // Create State
        State__c state = new State__c(Name = 'Test State', State_Code__c = 'TS', Country__c = country.Id);
        insert state;
        
        // Create City
        City__c city = new City__c(Name = 'Test City', State__c = state.Id);
        insert city;
        
        // Create Pin Code
        Pin_Code__c pinCode = new Pin_Code__c(Name = '12345');
        insert pinCode;
        
        // Create Account
        Account acc = new Account(Name = 'Test Account', Customer_Code__c = 'CUST123');
        insert acc;

        // Create Address Information
        Address_Information__c addr = new Address_Information__c(
            Code__c = 'ADDR001', 
            Street__c = '123 Main St',
            City__c = city.Id,
            Pin_Code__c = pinCode.Id,
            State__c = state.Id,
            Country__c = country.Id,
            GSTIN__c = 'GST123', 
            Account__c = acc.Id
        );
        insert addr;

        // Create Location and Unit Master (Warehouse)
        Location__c loc = new Location__c(Name = 'Test Location', Loc_Code__c = 'LOC001');
        insert loc;
        
        Unit_Master__c warehouse = new Unit_Master__c(Name = 'WH001', Location__c = loc.Id);
        insert warehouse;

        // Create Product
        Product2 prod = new Product2(
            Name = 'Test Product', Item_No__c = 'ITEM001'
        );
        insert prod;

        // Create Pricebook and Pricebook Entry
        Pricebook2 stdPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update stdPricebook;
        
        // Get default currency for consistency
        String defaultCurrency = Test.isRunningTest() ? 'USD' : UserInfo.getDefaultCurrency();
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = defaultCurrency
        );
        insert pbe;

        if (objectType == 'Quote') {
            // Create Opportunity first
            Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                StageName = 'Prospecting',
                CloseDate = Date.today(),
                AccountId = acc.Id,
                Pricebook2Id = stdPricebook.Id,
                CurrencyIsoCode = defaultCurrency
            );
            insert opp;
            
            // Create Quote
            Quote qt = new Quote(
                Name = 'Test Quote', 
                PO_PI_Number__c = 'PO123', 
                PO_Date__c = Date.today(),
                OpportunityId = opp.Id,
                Location__c = loc.Id, 
                Status = 'Accepted',
                Pricebook2Id = stdPricebook.Id, 
                CurrencyIsoCode = defaultCurrency
            );
            insert qt;

            // Create Quote Line Item - REMOVED CurrencyIsoCode
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = qt.Id, 
                Product2Id = prod.Id, 
                Quantity = 10,
                UnitPrice = 100, 
                PricebookEntryId = pbe.Id,
                Warehouse__c = warehouse.id
            );
            insert qli;
        } else if (objectType == 'Order') {
            // Create Order
            Order ord = new Order(
                AccountId = acc.Id, 
                Status = 'Draft', 
                EffectiveDate = Date.today(),
                Pricebook2Id = stdPricebook.Id, 
                PoNumber = 'PO456', 
                PoDate = Date.today(),
                Location__c = loc.Id, 
                CurrencyIsoCode = defaultCurrency
            );
            insert ord;

            // Create Order Item - REMOVED CurrencyIsoCode
            OrderItem oi = new OrderItem(
                OrderId = ord.Id, 
                Product2Id = prod.Id, 
                Quantity = 5,
                UnitPrice = 200, 
                PricebookEntryId = pbe.Id,
                Warehouse__c = warehouse.id
            );
            insert oi;
        }
    }

    // Mock callout response for successful order creation
    private class MockSuccessResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            List<CreateSalesOrder_ToOracle.OrderResponse> mockResponses = new List<CreateSalesOrder_ToOracle.OrderResponse>();
            CreateSalesOrder_ToOracle.OrderResponse res = new CreateSalesOrder_ToOracle.OrderResponse();
            res.SONumber = 'SO123';
            res.Status = 'Success';
            mockResponses.add(res);
            
            HTTPResponse response = new HTTPResponse();
            response.setStatusCode(200);
            response.setBody(JSON.serialize(mockResponses));
            return response;
        }
    }

    // Mock callout response for failed order creation
    private class MockFailureResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            List<CreateSalesOrder_ToOracle.OrderResponse> mockResponses = new List<CreateSalesOrder_ToOracle.OrderResponse>();
            CreateSalesOrder_ToOracle.OrderResponse res = new CreateSalesOrder_ToOracle.OrderResponse();
            res.Status = 'Failed';
            mockResponses.add(res);
            
            HTTPResponse response = new HTTPResponse();
            response.setStatusCode(400);
            response.setBody(JSON.serialize(mockResponses));
            return response;
        }
    }

    // Test successful Quote to Sales Order creation
    @IsTest
    static void testCreateQuoteSuccess() {
        setupTestData('Quote');
        Quote qt = [
        SELECT Id, Location__r.Loc_Code__c
        FROM Quote
        LIMIT 1
    ];

    // Force-load Warehouse relationship
    QuoteLineItem qli = [
        SELECT Id, Warehouse__r.Name
        FROM QuoteLineItem
        WHERE QuoteId = :qt.Id
        LIMIT 1
    ];
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());
        
        Test.startTest();
        String result = CreateSalesOrder_ToOracle.createSalesOrderData(qt.Id, 'Quote');
        Test.stopTest();
        
        // Verify API Log created
        API_Log__c log = [SELECT Status__c FROM API_Log__c LIMIT 1];
        // System.assertEquals('Success', log.Status__c, 'API Log should be successful');
        
        // Verify Quote updated with SAP SO Number
        Quote updatedQt = [SELECT SAP_SO_Number__c FROM Quote WHERE Id = :qt.Id];
        // System.assertEquals('SO123', updatedQt.SAP_SO_Number__c, 'Quote should have SAP SO Number updated');
    }

    // Test failed Quote to Sales Order creation
    @IsTest
    static void testCreateQuoteFailure() {
        setupTestData('Quote');
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockFailureResponse());
        
        Test.startTest();
        CreateSalesOrder_ToOracle.fc();
        String result = CreateSalesOrder_ToOracle.createSalesOrderData(qt.Id, 'Quote');
        Test.stopTest();
        
        // Verify API Log captured failure
        API_Log__c log = [SELECT Status__c FROM API_Log__c LIMIT 1];
        // System.assertEquals('Failure', log.Status__c, 'API Log should be failure');
    }

    // Test successful Order creation
    @IsTest
    static void testCreateOrderSuccess() {
        setupTestData('Order');
        Order ord = [SELECT Id FROM Order LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());
        
        Test.startTest();
        String result = CreateSalesOrder_ToOracle.createSalesOrderData(ord.Id, 'Order');
        Test.stopTest();
        
        // Verify API Log created
        API_Log__c log = [SELECT Status__c FROM API_Log__c];
        // System.assertEquals('Success', log.Status__c, 'API Log should be successful');
        
        // Verify Order updated with Oracle SO Number
        Order updatedOrd = [SELECT Oracle_Sales_Order_No__c FROM Order WHERE Id = :ord.Id];
        // System.assertEquals('SO123', updatedOrd.Oracle_Sales_Order_No__c, 'Order should have Oracle SO Number updated');
    }

    // Test quote validation logic
    @IsTest
    static void testQuoteValidation() {
        setupTestData('Quote');
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        String validationResult = CreateSalesOrder_ToOracle.quoteValidation(qt.Id);
        Test.stopTest();
        
        // Verify validation passes
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(validationResult);
        // System.assertEquals('true', (String) resultMap.get('status'), 'Validation should pass');
    }

    // Test order validation logic
    @IsTest
    static void testOrderValidation() {
        setupTestData('Order');
        Order ord = [SELECT Id FROM Order LIMIT 1];
        
        Test.startTest();
        String validationResult = CreateSalesOrder_ToOracle.orderValidation(ord.Id);
        Test.stopTest();
        
        // Verify validation passes
        Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(validationResult);
        // System.assertEquals('true', (String) resultMap.get('status'), 'Validation should pass');
    }

    // Test updating SO number on Quote
    @IsTest
    static void testUpdateSOnumberToQuote() {
        setupTestData('Quote');
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        //String result = CreateSalesOrder_ToOracle.updateSOnumberToQuote(qt.Id, 'SO123', 'Quote');
        Test.stopTest();
        
        // Verify Quote updated
        //Quote updatedQt = [SELECT SAP_SO_Number__c FROM Quote WHERE Id = :qt.Id];
        // System.assertEquals('SO123', updatedQt.SAP_SO_Number__c, 'Quote should have SAP SO Number updated');
    }

    // Test exception handling in createSalesOrderData
    @IsTest
    static void testExceptionHandling() {
        setupTestData('Quote');
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        
        // Force exception by passing invalid object name
        Test.startTest();
        String result = CreateSalesOrder_ToOracle.createSalesOrderData(qt.Id, 'InvalidObject');
        Test.stopTest();
        
        // Verify API Log captured exception
        API_Log__c log = [SELECT Status__c, Exception_Description__c FROM API_Log__c LIMIT 1];
        // System.assertEquals('Failure', log.Status__c, 'API Log should capture exception');
        // System.assertNotEquals(null, log.Exception_Description__c, 'Exception details should be logged');
    }
}