public class SampleInRequestTriggerHandler {
    
    public static void handleAfterUpdateEmail(List<Sample_In_Request__c> newList, Map<Id, Sample_In_Request__c> oldMap) {
        List<Id> requestIdsToEmail = new List<Id>();
        List<Sample_In__c> sampleInsToUpdate = new List<Sample_In__c>();

        for (Sample_In_Request__c newRec : newList) {
            if (newRec.Sample_In_Status__c == 'Sample Sent to Factory') {
                requestIdsToEmail.add(newRec.Id);

                // Fetch related Sample_In__c records
                List<Sample_In__c> relatedSamples = [
                    SELECT Id, Sample_In_Status__c
                    FROM Sample_In__c
                    WHERE Sample_In_Request__c = :newRec.Id
                ];

                for (Sample_In__c sample : relatedSamples) {
                    sample.Sample_In_Status__c = 'Sample Sent to Factory';
                    sampleInsToUpdate.add(sample);
                }
            }
        }

        // Update Sample_In__c records
        if (!sampleInsToUpdate.isEmpty()) {
            update sampleInsToUpdate;
        }

        // Trigger email
        for (Id reqId : requestIdsToEmail) {
            SampleInEmailSender.sendEmailAsync(reqId);
        }
    }
    
    public static void sendHOEmail(List<Sample_In_Request__c> newList, Map<Id, Sample_In_Request__c> oldMap) {
        for (Sample_In_Request__c newRec : newList) {
            if (newRec.Sample_In_Status__c == 'Sample Sent to HO') {
                SampleInEmailSender.sendHOEmailAsync(newRec.Id);
            }
        }
    }
    
       public static void captureStatusDates(List<Sample_In_Request__c> newList,Map<Id, Sample_In_Request__c> oldMap) {
        Date today = Date.today();
        
        for (Sample_In_Request__c newRec : newList) {
            
            Sample_In_Request__c oldRec =
                oldMap != null ? oldMap.get(newRec.Id) : null;
            
            Boolean statusChanged =
                oldRec == null ||
                newRec.Sample_In_Status__c != oldRec.Sample_In_Status__c;
            
            if (!statusChanged || newRec.Sample_In_Status__c == null) {
                continue;
            }
            
            switch on newRec.Sample_In_Status__c {
                
                when 'Sample In' {
                    if (newRec.Sample_In_Capture_Date__c == null)
                        newRec.Sample_In_Capture_Date__c = today;
                }
                
                when 'Sample Sent to Factory' {
                    if (newRec.Sample_Sent_Factory_Capture_Date__c == null)
                        newRec.Sample_Sent_Factory_Capture_Date__c = today;
                }
                
                when 'Sample Sent to HO' {
                    if (newRec.Sample_Sent_to_Ho_Capture_Date__c == null)
                        newRec.Sample_Sent_to_Ho_Capture_Date__c = today;
                }
                
                when 'In Progress' {
                    if (newRec.In_Progress_Capture_Date__c == null)
                        newRec.In_Progress_Capture_Date__c = today;
                }
                
                when 'Approved' {
                    if (newRec.Approved_Date__c == null)
                        newRec.Approved_Date__c = today;
                }
                
                when 'Rejected' {
                    if (newRec.Rejected_Date__c == null)
                        newRec.Rejected_Date__c = today;
                }
            }
        }
    }

}