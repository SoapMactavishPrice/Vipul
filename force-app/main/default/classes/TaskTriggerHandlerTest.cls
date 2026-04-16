@isTest
public class TaskTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New'
        );
        insert testLead;
    }
    
    @isTest
    static void testUpdateLeadStatus() {
        // Fetch test Lead
        Lead testLead = [SELECT Id, Status FROM Lead LIMIT 1];

        // Create a task associated with the test Lead
        Task testTask = new Task(
            WhoId = testLead.Id,
            Subject = 'Follow-up Call',
            Status = 'Completed'
        );
        insert testTask;

        // Invoke the method to be tested
        Test.startTest();
        TaskTriggerHandler.updateLeadStatus(new List<Task>{testTask});
        Test.stopTest();

        // Retrieve the updated Lead and assert expected changes
        Lead updatedLead = [SELECT Id, Status, Task_Count__c FROM Lead WHERE Id = :testLead.Id];
        
        System.assertEquals('Contacted', updatedLead.Status, 'Lead Status should be updated to Contacted');
        System.assertEquals(1, updatedLead.Task_Count__c, 'Task_Count__c should be updated to 1');
    }
}