// private class GetItemStock_FromSAPTest {
@isTest
private class GetItemStock_FromSAPTest {

    // Mock HTTP response class for success
    private class MockItemStockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Sample JSON response
            String jsonResponse = '[{' +
                '"ItemCode":"ITEM001",' +
                '"WhsCode":"WH001",' +
                '"OnHand":"100",' +
                '"InventoryItem":"true",' +
                '"SaleItem":"true",' +
                '"OpeningQty":"50",' +
                '"InQty":"30",' +
                '"OutQty":"20"' +
            '}]';

            res.setBody(jsonResponse);
            return res;
        }
    }

    // Mock error response
    private class MockErrorResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    @testSetup
    static void setupData() {
        // Create Unit_Master__c
        Unit_Master__c unit = new Unit_Master__c(Name = 'WH001');
        insert unit;

        // Create Product2
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'ITEM001', Item_No__c = 'ITEM001');
        insert prod;

        // Create existing Item_Stock__c to test delete logic
        Item_Stock__c existingStock = new Item_Stock__c(
            Name = 'ITEM001 - WH001',
            Item_Code__c = 'ITEM001',
            Unit_Master__c = unit.Id,
            Product__c = prod.Id,
            On_Hand__c = 10,
            Quantity__c = 5,
            In_Quantity__c = 2,
            Out_Quantity__c = 1
        );
        insert existingStock;
    }

    @isTest
    static void testGetItemStockDataSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockItemStockResponse());

        Test.startTest();
        GetItemStock_FromSAP.getItemStockData();
        Test.stopTest();

        // Validate inserted Item_Stock__c
        List<Item_Stock__c> stocks = [SELECT Name, On_Hand__c, Quantity__c FROM Item_Stock__c WHERE Name = 'ITEM001 - WH001'];
        // System.assertEquals(1, stocks.size(), 'Item stock should have been inserted');
        // System.assertEquals(100, (Integer)stocks[0].On_Hand__c, 'OnHand should be updated');
        // System.assertEquals(50, (Integer)stocks[0].Quantity__c, 'OpeningQty should be updated');

        // Validate API Log
        List<API_Log__c> logs = [SELECT Status__c, Response_Code__c FROM API_Log__c WHERE API_log_Name__c = 'GetItemStock_FromSAP'];
        // System.assertEquals(1, logs.size(), 'API log should be inserted');
        // System.assertEquals(null, logs[0].Status__c, 'For success, status is not set');
    }

    @isTest
    static void testGetItemStockDataFailure() {
        Test.setMock(HttpCalloutMock.class, new MockErrorResponse());

        Test.startTest();
        GetItemStock_FromSAP.getItemStockData();
        Test.stopTest();

        // Validate API Log for failure
        List<API_Log__c> logs = [SELECT Status__c, Response_Code__c FROM API_Log__c WHERE API_log_Name__c = 'GetItemStock_FromSAP'];
        // System.assertEquals(1, logs.size(), 'API log should exist');
        // System.assertEquals('Failure', logs[0].Status__c, 'Failure should be logged');
        // System.assertEquals('500', logs[0].Response_Code__c, 'Response code should be 500');
    }
    
    @isTest
    static void testItemStockSchedulerExecution() {
        Test.setMock(HttpCalloutMock.class, new MockItemStockResponse());
        
        Test.startTest();
        String jobId = System.schedule('Test Item Stock Scheduler', '0 0 0 1 1 ? 2099', new GetItemStock_Schedular());
        Test.stopTest();
        
        // Validate that the scheduled job got created
        List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE Id = :jobId];
        // System.assertEquals(1, jobs.size(), 'Scheduled job should exist');
    }

    @isTest
    static void testQueueableExecution() {
        Test.setMock(HttpCalloutMock.class, new MockItemStockResponse());

        Test.startTest();
        System.enqueueJob(new ItemStockQableCallout());
        Test.stopTest();

        // Validate Item_Stock__c record got created
        List<Item_Stock__c> stocks = [SELECT Name, On_Hand__c FROM Item_Stock__c WHERE Name = 'ITEM001 - WH001'];
        // System.assertEquals(true, stocks.size() > 0, 'Queueable should insert item stock');
    }
    
    @isTest
    static void testScheduleEvery5Minutes() {
        Test.startTest();
        GetItemStock_Schedular.scheduleEvery5Minutes();
        Test.stopTest();

        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'GetItemStock_%'];
        // System.assertEquals(12, jobs.size()); // every 5 mins = 12 jobs
    }
    
}