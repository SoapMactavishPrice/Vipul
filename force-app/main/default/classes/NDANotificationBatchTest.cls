@isTest
public class NDANotificationBatchTest {
    
    @testSetup
    static void setup() {
        // Create test data
        List<Document_Detail__c> docs = new List<Document_Detail__c>();
        for (Integer i = 0; i < 10; i++) {
            docs.add(new Document_Detail__c(
                Name = 'Test Document ' + i,
                End_Date__c = Date.today().addDays(15),
                OwnerId = UserInfo.getUserId()
            ));
        }
        insert docs;
    }
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        NDANotificationBatch batch = new NDANotificationBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify emails were sent
        //List<Messaging.SingleEmailMessage> sentEmails = [SELECT Id FROM Messaging.SingleEmailMessage];
        
    }
}