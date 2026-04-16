public class SampleRequestTriggerHandler {
    public static void handleAfterInsertOrUpdate(List<Sample_Request__c> newRequests) {
        System.debug('Entered handleAfterInsertOrUpdate method');
        
        for (Sample_Request__c request : newRequests) {
            System.debug('Processing Sample_Request__c record: ' + request.Id);

            // Call a future method to handle the email sending logic
         //   SampleRequestEmailSender.sendEmailAsync(request.Id);
        }
    }
}