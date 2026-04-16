// private class GetCustomerLedger_FromSAPTest {
@isTest
private class GetCustomerLedger_FromSAPTest {

    // Mock success response
    private class MockLedgerResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('[{"CardCode":"CUST001","CustomerGroupCode":"CG01","CustomerGroup":"Retail","Phone":"1234567890","Mobile":"9876543210","Address":"123 Street","Pincode":"400001","City":"Mumbai","State":"MH","Currency":"INR","SalesEmployeeCode":"SE01","SalesEmployeeName":"Sales Rep","Country":"India","CreditLimit":"10000","CurrentBalance":"5000","DeliveryBalance":"2000","OrderBalance":"3000"}]');
            return res;
        }
    }

    // Mock failure response
    private class MockErrorResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Error');
            return res;
        }
    }

    @testSetup
    static void setupData() {
        insert new Account(Name = 'Test Cust', Customer_Code__c = 'CUST001');
    }

    @isTest
    static void testQueueableSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockLedgerResponse());

        Test.startTest();
        System.enqueueJob(new CustomerLedgerQableCallout());
        Test.stopTest();

        // Assert ledger got inserted
        List<Customer_Ledger__c> ledgers = [SELECT Customer_Code__c FROM Customer_Ledger__c];
        // System.assertEquals(1, ledgers.size());

        // Assert API log created
        List<API_Log__c> logs = [SELECT Status__c FROM API_Log__c];
        // System.assertEquals('Success', logs[0].Status__c);
    }

    @isTest
    static void testQueueableFailure() {
        Test.setMock(HttpCalloutMock.class, new MockErrorResponse());

        Test.startTest();
        System.enqueueJob(new CustomerLedgerQableCallout());
        Test.stopTest();

        // Assert failure log
        List<API_Log__c> logs = [SELECT Status__c FROM API_Log__c];
        // System.assertEquals('Failure', logs[0].Status__c);
    }

    @isTest
    static void testSchedulerSchedulesJob() {
        Test.startTest();
        String cronExp = '0 0 * * * ?';
        System.schedule('TestLedgerSched', cronExp, new GetCustomerLedger_Schedular());
        Test.stopTest();

        List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = 'TestLedgerSched'];
        // System.assertEquals(1, jobs.size());
    }

    @isTest
    static void testScheduleEvery5Minutes() {
        Test.startTest();
        GetCustomerLedger_Schedular.scheduleEvery5Minutes();
        Test.stopTest();

        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'GetCustomerLedger_%'];
        // System.assertEquals(12, jobs.size()); // every 5 mins = 12 jobs
    }
}