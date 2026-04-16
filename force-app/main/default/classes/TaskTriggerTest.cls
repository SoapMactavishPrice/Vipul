@isTest
private class TaskTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Lead record
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open' // Initial status
        );
        insert testLead;
    }
    
    @isTest
    static void testTaskInsert() {
        // Fetch the test Lead
        Lead testLead = [SELECT Id, Status FROM Lead LIMIT 1];
        
        // Create a Task associated with the Lead
        Task testTask = new Task(
            Subject = 'Follow-up Call',
            Status = 'Completed',
            WhoId = testLead.Id
        );
        
        Test.startTest();
        insert testTask;
        Test.stopTest();
        
        // Fetch the updated Lead and verify status change
        testLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
        System.assertNotEquals('Open', testLead.Status, 'Lead status should be updated after task creation');
    }
    
    @isTest
    static void testTaskDelete() {
        // Fetch the test Lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Create and insert a Task
        Task testTask = new Task(
            Subject = 'Meeting Scheduled',
            Status = 'Completed',
            WhoId = testLead.Id
        );
        insert testTask;

        // Delete the Task
        Test.startTest();
        delete testTask;
        Test.stopTest();
        
        // Verify that lead status is correctly handled after Task deletion
        testLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
        System.assertNotEquals('Open', testLead.Status, 'Lead status should be handled correctly after task deletion');
    }
    
    @isTest
    static void testTaskUndelete() {
        // Fetch the test Lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Create and insert a Task
        Task testTask = new Task(
            Subject = 'Client Follow-up',
            Status = 'Completed',
            WhoId = testLead.Id
        );
        insert testTask;

        // Delete the Task
        delete testTask;
        
        // Restore the Task (undelete)
        Test.startTest();
        undelete testTask;
        Test.stopTest();
        
        // Verify that lead status is correctly updated after undelete
        testLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
        System.assertNotEquals('Open', testLead.Status, 'Lead status should be handled after task undelete');
    }
}