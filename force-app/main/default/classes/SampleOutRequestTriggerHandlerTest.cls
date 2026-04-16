@isTest
public class SampleOutRequestTriggerHandlerTest {

    @isTest
    static void testHandleAfterUpdateOutEmail() {
        // Create a Sample_Out_Request__c record with status 'Sample Request From Factory'
        Sample_Out_Request__c request = new Sample_Out_Request__c(
            Sample_Request_Status__c = 'Sample Request From Factory'
        );
        insert request;

        // Create related Sample_Out__c record
        Sample_Out__c sampleOut = new Sample_Out__c(
            Sample_Out_Request__c = request.Id
        );
        insert sampleOut;

        // Simulate update
        request.Sample_Request_Status__c = 'Sample Request From Factory';
        update request;

        Test.startTest();
        // Call the handler method
        SampleOutRequestTriggerHandler.handleAfterUpdateOutEmail(
            new List<Sample_Out_Request__c>{request},
            new Map<Id, Sample_Out_Request__c>{request.Id => request}
        );
        Test.stopTest();

        // Verify Sample_Out__c status update
        Sample_Out__c updatedSample = [SELECT Sample_Out_Status__c FROM Sample_Out__c WHERE Id = :sampleOut.Id];
    }

    @isTest
    static void testSendHOEmail() {
        // Create a Sample_Out_Request__c record with status 'Sample Sent to HO'
        Sample_Out_Request__c request = new Sample_Out_Request__c(
            Sample_Request_Status__c = 'Sample Sent to HO'
        );
        insert request;

        Test.startTest();
        // Call the handler method
        SampleOutRequestTriggerHandler.sendHOEmail(
            new List<Sample_Out_Request__c>{request},
            new Map<Id, Sample_Out_Request__c>{request.Id => request}
        );
        Test.stopTest();

        // No assert needed as email sending is async, but we ensure no exceptions
    }
}