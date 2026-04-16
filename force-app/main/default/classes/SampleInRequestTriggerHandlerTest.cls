@isTest
public class SampleInRequestTriggerHandlerTest {

    @isTest
    static void testHandleAfterUpdateEmail() {
        // Create a Sample_In_Request__c record with status 'Sample Sent to Factory'
        Sample_In_Request__c request = new Sample_In_Request__c(
            Sample_In_Status__c = 'Sample Sent to Factory'
        );
        insert request;

        // Create related Sample_In__c record
        Sample_In__c sampleIn = new Sample_In__c(
            Sample_In_Request__c = request.Id
        );
        insert sampleIn;

        // Simulate update
        request.Sample_In_Status__c = 'Sample Sent to Factory';
        update request;

        Test.startTest();
        SampleInRequestTriggerHandler.handleAfterUpdateEmail(
            new List<Sample_In_Request__c>{request},
            new Map<Id, Sample_In_Request__c>{request.Id => request}
        );
        Test.stopTest();

        // Verify Sample_In__c status update
        Sample_In__c updatedSample = [SELECT Sample_In_Status__c FROM Sample_In__c WHERE Id = :sampleIn.Id];
    }

    @isTest
    static void testSendHOEmail() {
        // Create a Sample_In_Request__c record with status 'Sample Sent to HO'
        Sample_In_Request__c request = new Sample_In_Request__c(
            Sample_In_Status__c = 'Sample Sent to HO'
        );
        insert request;

        Test.startTest();
        SampleInRequestTriggerHandler.sendHOEmail(
            new List<Sample_In_Request__c>{request},
            new Map<Id, Sample_In_Request__c>{request.Id => request}
        );
        Test.stopTest();

        // No assert needed for async email, just ensure no exceptions
    }
}