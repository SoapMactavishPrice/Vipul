@isTest
public class QuoteExpiryNotificationBatchTest {
    
    @testSetup
    static void setup() {
        // Create test data

        Account acc = new Account();
        acc.Name = 'Finesse';
        acc.INCO_Terms__c = 'DDP';
        insert acc;

        Contact con = new Contact();
        con.AccountId = acc.id;
        con.FirstName = 'Prashant';
        con.LastName = 'Padal';
        con.Email = 'Prashantpadal@finessedirect.com';
        con.Phone = '123-456-7890';
        insert con;
        
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Finesse';
        opp.StageName = 'Sampling';
        opp.CloseDate = Date.today();
        opp.AccountId = acc.Id;
        //opp.Contact__c = con.Id;
        //opp.Pricebook2Id=PID;
        
        insert opp;
        
        List<Quote> quotes = new List<Quote>();
        for (Integer i = 0; i < 10; i++) {
            quotes.add(new Quote(
                Name = 'Test Quote ' + i,
                ExpirationDate = Date.today().addDays(7),
                OwnerId = UserInfo.getUserId(),
                OpportunityId = opp.Id
            ));
        }
        insert quotes;
    }
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        QuoteExpiryNotificationBatch batch = new QuoteExpiryNotificationBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
    }
    
    @isTest
    static void testSchedulerExecution() {
        Test.startTest();
        // Schedule the job
        String jobId = System.schedule('Test QuoteExpiryNotificationScheduler', '0 0 0 * * ?', new QuoteExpiryNotificationScheduler());
        Test.stopTest();
        
        // Verify the job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE Id = :jobId];
    }
}