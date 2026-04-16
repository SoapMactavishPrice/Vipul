public class SampleOutRequestTriggerHandler {
    
    public static void handleAfterUpdateOutEmail(List<Sample_Out_Request__c> newList, Map<Id, Sample_Out_Request__c> oldMap) {
        List<Id> requestIdsToEmail = new List<Id>();
        List<Sample_Out__c> sampleOutsToUpdate = new List<Sample_Out__c>();

        for (Sample_Out_Request__c newRec : newList) {
            if (newRec.Sample_Request_Status__c == 'Sample Request From Factory') {
                requestIdsToEmail.add(newRec.Id);

                // Fetch related Sample_Out__c records
                List<Sample_Out__c> relatedSamples = [
                    SELECT Id
                    FROM Sample_Out__c
                    WHERE Sample_Out_Request__c = :newRec.Id
                ];

                for (Sample_Out__c sample : relatedSamples) {
                    sample.Sample_Out_Status__c = 'Sample Request From Factory';
                    sampleOutsToUpdate.add(sample);
                }
            }
        }

        // Update Sample_Out__c records
        if (!sampleOutsToUpdate.isEmpty()) {
            update sampleOutsToUpdate;
        }

        // Trigger email
        for (Id reqId : requestIdsToEmail) {
            SampleOutEmailSender.sendEmailAsync(reqId);
        }
    }
    
    public static void sendHOEmail(List<Sample_Out_Request__c> newList, Map<Id, Sample_Out_Request__c> oldMap) {
        for (Sample_Out_Request__c newRec : newList) {
            if (newRec.Sample_Request_Status__c == 'Sample Sent to HO') {
                SampleOutEmailSender.sendHOEmailAsync(newRec.Id);
            }
        }
    }
}