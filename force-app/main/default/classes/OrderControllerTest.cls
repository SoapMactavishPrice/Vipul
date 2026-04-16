@isTest
private class OrderControllerTest {
    
        @TestSetup
        static void setupData() {
            // Create Account
            Account acc = new Account(
                Name = 'Test Account',
                Buyer_s_Ref_PO__c = 'PO12345',
                Buyer_s_PO_Date__c = Date.today()
            );
            insert acc;
    
            // Create Product
            Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
            insert prod;
            
            Pricebook2 pb = new Pricebook2(
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            update pb;
    
    
            // Create PricebookEntry
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = pb.Id,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true,
                CurrencyIsoCode = 'USD'
            );
            insert pbe;
        }

    @isTest
    static void testCreateOrUpdateOrder() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

        // Prepare orderFields JSON
        Map<String, Object> orderFields = new Map<String, Object>{
            'EffectiveDate' => String.valueOf(Date.today()),
            'CurrencyIsoCode' => 'USD',
                'Status' => 'Draft',
                'Order_Type__c' => 'International'
        };
        String orderFieldsJson = JSON.serialize(orderFields);

        // Prepare orderLineItems JSON
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'prodId' => prod.Id,
                'Quantity' => 2,
                'UnitPrice' => 100,
                'CommissionType' => 'Value',
                'commissionval' => 20,
                'quality' => 'High',
                'freightval' => 50
            }
        };
        String lineItemsJson = JSON.serialize(lineItems);

        Test.startTest();
        Id orderId = OrderController.createOrUpdateOrder(acc.Id, orderFieldsJson, lineItemsJson);
        Test.stopTest();


        // Verify Order and OrderItems
        Order ord = [SELECT Id, AccountId FROM Order WHERE Id = :orderId];

        List<OrderItem> items = [SELECT Id, OrderId FROM OrderItem WHERE OrderId = :orderId];
    }

    @isTest
    static void testMissingPricebookEntry() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Prepare orderFields JSON
        Map<String, Object> orderFields = new Map<String, Object>{
            'EffectiveDate' => String.valueOf(Date.today()),
            'CurrencyIsoCode' => 'EUR' // Currency not matching any PricebookEntry
        };
        String orderFieldsJson = JSON.serialize(orderFields);

        // Prepare orderLineItems JSON
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>{
            new Map<String, Object>{
                'prodId' => [SELECT Id FROM Product2 LIMIT 1].Id,
                'Quantity' => 1
            }
        };
        String lineItemsJson = JSON.serialize(lineItems);

        Test.startTest();
        try {
            OrderController.createOrUpdateOrder(acc.Id, orderFieldsJson, lineItemsJson);
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetOrders() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Order> orders = OrderController.getOrders(acc.Id);
    }

   /* @isTest
    static void testGetOrderDetails() {
        Order ord = [SELECT Id FROM Order LIMIT 1];
        Map<String, Object> details = OrderController.getOrderDetails(ord.Id);
    }*/

    @isTest
    static void testGetOrderPicklistValues() {
        List<Map<String, String>> picklistValues = OrderController.getOrderPicklistValues();
    }

    @isTest
    static void testGetUserInfoWithOrderType() {
        Map<String, Object> result = OrderController.getUserInfoWithOrderType();
    }

    @isTest
    static void testGetCheckListsByAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Check_List__c> checklists = OrderController.getCheckListsByAccount(acc.Id);
    }
}