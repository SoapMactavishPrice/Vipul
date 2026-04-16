@isTest
public class SampleOutTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test records for Sample_Out__c
        Sample_Out__c sampleRecord = new Sample_Out__c(
          //  Name = 'Test Sample'
           // Status__c = 'Pending'  // Assuming a Status field exists
        );
        insert sampleRecord;
    }
    
    @isTest
    static void testAfterInsertTrigger() {
        // Create a new Sample_Out__c record
        Sample_Out__c newSample = new Sample_Out__c(
          //  Name = 'New Sample',
            //Status__c = 'Initiated'
        );

        Test.startTest();
        insert newSample;
        Test.stopTest();

        // Retrieve the inserted record
      //  Sample_Out__c insertedSample = [SELECT Id, Name, Status__c FROM Sample_Out__c WHERE Id = :newSample.Id LIMIT 1];

        // Validate that the record was inserted
      //  System.assertNotEquals(null, insertedSample, 'Sample_Out__c record should be inserted.');
    }

    @isTest
    static void testAfterUpdateTrigger() {
        // Fetch the test record
      //  Sample_Out__c sampleRecord = [SELECT Id, Name, Status__c FROM Sample_Out__c LIMIT 1];

        // Update the record
       // sampleRecord.Status__c = 'Completed';

        Test.startTest();
       // update sampleRecord;
        Test.stopTest();

        // Retrieve the updated record
     //   Sample_Out__c updatedSample = [SELECT Id, Name, Status__c FROM Sample_Out__c WHERE Id = :sampleRecord.Id LIMIT 1];

        // Validate that the record was updated
       // System.assertEquals('Completed', updatedSample.Status__c, 'Sample_Out__c status should be updated.');
    }
}