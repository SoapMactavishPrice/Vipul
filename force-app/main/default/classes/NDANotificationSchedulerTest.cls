@isTest
private class NDANotificationSchedulerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test data for Account
        Account testAccount = new Account(Name = 'Test Account ' + DateTime.now().getTime(), INCO_Terms__c = 'DDP'); // Make account name unique
        insert testAccount;
        
        // Create a User record to be the owner
        User testUser = new User(
            Alias = 'testusr', 
            Email = 'testuser@example.com', 
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id, 
            Username = 'testuser_' + DateTime.now().getTime() + '@example.com', // Make the username unique
            FirstName = 'Test', 
            LastName = 'User', 
            TimeZoneSidKey = 'America/New_York', 
            LocaleSidKey = 'en_US', 
            EmailEncodingKey = 'UTF-8', 
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Create Document_Detail__c records with unique names to avoid duplicates
        Document_Detail__c doc1 = new Document_Detail__c(
            Name = 'Document 1 ' + DateTime.now().getTime(), // Unique Name
            OwnerId = testUser.Id, 
            End_Date__c = Date.today().addDays(15)
        );
        insert doc1;
        
        Document_Detail__c doc2 = new Document_Detail__c(
            Name = 'Document 2 ' + DateTime.now().getTime(), // Unique Name
            OwnerId = testUser.Id, 
            End_Date__c = Date.today().addDays(30)
        );
        insert doc2;
    }
    
    @isTest
    static void testSchedulerExecution() {
        // Create an instance of the scheduler
        NDANotificationScheduler scheduler = new NDANotificationScheduler();
        
        // Schedule the job to run immediately
        String cronExpression = '0 0 0 1 1 ?';  // This cron expression is a placeholder
        System.schedule('Test NDANotificationScheduler', cronExpression, scheduler);
        
        // Verify that the job was scheduled
        CronTrigger scheduledJob = [SELECT Id, CronExpression, State FROM CronTrigger WHERE CronJobDetail.Name = 'Test NDANotificationScheduler' LIMIT 1];
        
        // Make sure the cron expression was correctly set
        System.assertEquals('0 0 0 1 1 ?', scheduledJob.CronExpression);
        
        // Optionally, add a check to verify that the batch was executed successfully.
        // For example, check if the batch class executed as expected. This can be done by checking 
        // debug logs or system logs for batch completion.
    }
}