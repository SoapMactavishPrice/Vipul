public class SampleOutTriggerHandler {
    
  /*  public static void captureStatusChangeDates(List<Sample_Out__c> newList, Map<Id, Sample_Out__c> oldMap) {
        for (Sample_Out__c newRec : newList) {
            Sample_Out__c oldRec = oldMap.get(newRec.Id);

            if (oldRec.Sample_Out_Status__c != newRec.Sample_Out_Status__c) {
                String newStatus = newRec.Sample_Out_Status__c;

                Date today = Date.today();

                if (newStatus == 'Sample Sent to Customer' && newRec.Sample_Sent_to_Customer_Date__c == null) {
                    newRec.Sample_Sent_to_Customer_Date__c = today;
                } else if (newStatus == 'Sample Sent to HO' && newRec.Sample_Sent_to_HO_Date__c == null) {
                    newRec.Sample_Sent_to_HO_Date__c = today;
                } else if (newStatus == 'Sample Rejected' && newRec.Sample_Rejected_Date__c == null) {
                    newRec.Sample_Rejected_Date__c = today;
                } else if (newStatus == 'Sample Approved' && newRec.Sample_Approved_Date__c == null) {
                    newRec.Sample_Approved_Date__c = today;
                }
            }
        }
    }  */
    
    public static void captureStatusChangeDates(List<Sample_Out__c> newList, Map<Id, Sample_Out__c> oldMap) {
    Date today = Date.today();

    for (Sample_Out__c newRec : newList) {
        Sample_Out__c oldRec = (oldMap != null && oldMap.containsKey(newRec.Id)) ? oldMap.get(newRec.Id) : null;

        // Only capture date if status is changed or new record
        if (oldRec == null || oldRec.Sample_Out_Status__c != newRec.Sample_Out_Status__c) {
            switch on newRec.Sample_Out_Status__c {
                when 'Sample Request from Factory' {
                    if (newRec.Sample_Request_from_Factory_Date__c == null)
                        newRec.Sample_Request_from_Factory_Date__c = today;
                }
                when 'Sample Sent to HO' {
                    if (newRec.Sample_Sent_to_HO_Date__c == null)
                        newRec.Sample_Sent_to_HO_Date__c = today;
                }
                when 'Re-Sampling' {
                    if (newRec.Re_Sampling_Date__c == null)
                        newRec.Re_Sampling_Date__c = today;
                }
                when 'Sample Sent to Customer' {
                    if (newRec.Sample_Sent_to_Customer_Date__c == null)
                        newRec.Sample_Sent_to_Customer_Date__c = today;
                }
                when 'Under Evaluation' {
                    if (newRec.Under_Evaluation_Date__c == null)
                        newRec.Under_Evaluation_Date__c = today;
                }
                when 'On Hold' {
                    if (newRec.On_Hold_Date__c == null)
                        newRec.On_Hold_Date__c = today;
                }
                when 'Sample Approved' {
                    if (newRec.Sample_Approved_Date__c == null)
                        newRec.Sample_Approved_Date__c = today;
                }
                when 'Sample Rejected' {
                    if (newRec.Sample_Rejected_Date__c == null)
                        newRec.Sample_Rejected_Date__c = today;
                }
            }
        }
    }
}

    
    public static void populateFieldsFromRequest(List<Sample_Out__c> sampleOutList) {
        Set<Id> requestIds = new Set<Id>();

        // Collect all Sample_Out_Request__c IDs
        for (Sample_Out__c so : sampleOutList) {
            if (so.Sample_Out_Request__c != null) {
                requestIds.add(so.Sample_Out_Request__c);
            }
        }

        // Query related Sample_Out_Request__c records
        Map<Id, Sample_Out_Request__c> requestMap = new Map<Id, Sample_Out_Request__c>(
            [SELECT Id, Country__c, Company_Name__c FROM Sample_Out_Request__c WHERE Id IN :requestIds]
        );

        // Populate fields on Sample_Out__c
        for (Sample_Out__c so : sampleOutList) {
            if (so.Sample_Out_Request__c != null && requestMap.containsKey(so.Sample_Out_Request__c)) {
                Sample_Out_Request__c relatedRequest = requestMap.get(so.Sample_Out_Request__c);
                so.Country__c = relatedRequest.Country__c;
                so.Company_Name__c = relatedRequest.Company_Name__c;
            }
        }
    }
    

   public static void createSampleOutRecords(List<Sample_Out__c> sampleInList) {
        Map<Id, Sample_Out__c> validSampleInMap = new Map<Id, Sample_Out__c>();

        for (Sample_Out__c sampleIn : sampleInList) {
            if ((sampleIn.Product_Name__c != null || sampleIn.New_Product_Name__c != null) &&
                sampleIn.Sample_Out_Status__c == 'Sample Sent to Customer') {
                validSampleInMap.put(sampleIn.Id, sampleIn);
            }
        }

        if (validSampleInMap.isEmpty()) return;

        // Query existing Sample_Out_Products__c records to avoid duplicates
        Set<Id> existingRequestedProductIds = new Set<Id>();
        for (Sample_Out_Products__c sampleOut : [
            SELECT Requested_Product__c
            FROM Sample_Out_Products__c
            WHERE Requested_Product__c IN :validSampleInMap.keySet()
        ]) {
            existingRequestedProductIds.add(sampleOut.Requested_Product__c);
        }

        List<Sample_Out_Products__c> toInsert = new List<Sample_Out_Products__c>();

        for (Sample_Out__c sampleIn : validSampleInMap.values()) {
            if (!existingRequestedProductIds.contains(sampleIn.Id)) {
                Sample_Out_Products__c newSampleOut = new Sample_Out_Products__c();
                newSampleOut.Requested_Product__c = sampleIn.Id;
                newSampleOut.Product__c = sampleIn.Product_Name__c;
                newSampleOut.Quantity__c = sampleIn.Quantity__c;
                newSampleOut.Quality__c = sampleIn.Quality__c;
                newSampleOut.Reference_Number__c = sampleIn.Reference_Number__c;
                newSampleOut.Application__c = sampleIn.Application__c;
                newSampleOut.Sample_Sent_to_Unit__c = sampleIn.Sample_Sent_to_Unit__c;
                newSampleOut.Tracking_Number__c = sampleIn.Tracking_Number__c;
                newSampleOut.Sample_Out_Status__c = 'Sample Sent to Customer';
                newSampleOut.Packets__c = sampleIn.Packets__c;
                newSampleOut.New_Product__c = sampleIn.New_Product__c;
                newSampleOut.New_Product_Name__c = sampleIn.New_Product_Name__c;
                newSampleOut.New_Product_CI_No__c = sampleIn.New_Product_CI_No__c;
                newSampleOut.Company_Name__c = sampleIn.Company_Name__c;
                toInsert.add(newSampleOut);
            }
        }

        if (!toInsert.isEmpty()) insert toInsert;
    }
    
    
    public static void syncStatusToSampleOut(List<Sample_Out__c> newList, Map<Id, Sample_Out__c> oldMap) {
        Map<String, String> reverseStatusMapping = new Map<String, String>{
            'Sample Sent to Customer' => 'Sample Sent to Customer',
            'Under Evaluation'        => 'Under Evaluation',
            'On Hold'                 => 'On Hold',
            'Sample Approved'         => 'Sample Approved',
            'Sample Rejected'         => 'Sample Rejected'
        };

        Set<Id> changedSampleOutIds = new Set<Id>();

        for (Sample_Out__c newRec : newList) {
            Sample_Out__c oldRec = oldMap.get(newRec.Id);
            if (oldRec == null) continue;

            Boolean hasChanged = false;

            if (newRec.Sample_Out_Status__c != oldRec.Sample_Out_Status__c &&
                reverseStatusMapping.containsKey(newRec.Sample_Out_Status__c)) {
                hasChanged = true;
            }

            if (
                newRec.Product_Name__c != oldRec.Product_Name__c ||
                newRec.Quantity__c != oldRec.Quantity__c ||
                newRec.Quality__c != oldRec.Quality__c ||
                newRec.Reference_Number__c != oldRec.Reference_Number__c ||
                newRec.Application__c != oldRec.Application__c ||
                newRec.Sample_Sent_to_Unit__c != oldRec.Sample_Sent_to_Unit__c ||
                newRec.Tracking_Number__c != oldRec.Tracking_Number__c ||
                newRec.Packets__c != oldRec.Packets__c ||
                newRec.New_Product__c != oldRec.New_Product__c ||
                newRec.New_Product_Name__c != oldRec.New_Product_Name__c ||
                newRec.New_Product_CI_No__c != oldRec.New_Product_CI_No__c
            ) {
                hasChanged = true;
            }

            if (hasChanged) {
                changedSampleOutIds.add(newRec.Id);
            }
        }

        if (changedSampleOutIds.isEmpty()) return;

        // Step 1: Query latest Sample_Out_Products__c per Sample_Out__c
        List<Sample_Out_Products__c> allRelatedSOPs = [
            SELECT Id, Requested_Product__c, Sample_Out_Status__c, Quality__c,
                   Product__c, Quantity__c, Reference_Number__c, Application__c,
                   Sample_Sent_to_Unit__c, Tracking_Number__c, Packets__c,
                   New_Product__c, New_Product_Name__c, New_Product_CI_No__c, CreatedDate
            FROM Sample_Out_Products__c
            WHERE Requested_Product__c IN :changedSampleOutIds
            ORDER BY Requested_Product__c, CreatedDate DESC
        ];

        Map<Id, Sample_Out_Products__c> latestSOPMap = new Map<Id, Sample_Out_Products__c>();
        for (Sample_Out_Products__c sop : allRelatedSOPs) {
            if (!latestSOPMap.containsKey(sop.Requested_Product__c)) {
                latestSOPMap.put(sop.Requested_Product__c, sop);
            }
        }

        List<Sample_Out_Products__c> updates = new List<Sample_Out_Products__c>();

        for (Id sampleOutId : changedSampleOutIds) {
            Sample_Out__c newRec;
            for (Sample_Out__c s : newList) {
                if (s.Id == sampleOutId) {
                    newRec = s;
                    break;
                }
            }
            if (newRec == null || !latestSOPMap.containsKey(sampleOutId)) continue;

            Sample_Out_Products__c sop = latestSOPMap.get(sampleOutId);
            Boolean needsUpdate = false;

            if (sop.Sample_Out_Status__c != newRec.Sample_Out_Status__c &&
                reverseStatusMapping.containsKey(newRec.Sample_Out_Status__c)) {
                sop.Sample_Out_Status__c = reverseStatusMapping.get(newRec.Sample_Out_Status__c);
                needsUpdate = true;
            }

            if (sop.Product__c != newRec.Product_Name__c) {
                sop.Product__c = newRec.Product_Name__c;
                needsUpdate = true;
            }
            if (sop.Quantity__c != newRec.Quantity__c) {
                sop.Quantity__c = newRec.Quantity__c;
                needsUpdate = true;
            }
            if (sop.Quality__c != newRec.Quality__c) {
                sop.Quality__c = newRec.Quality__c;
                needsUpdate = true;
            }
            if (sop.Reference_Number__c != newRec.Reference_Number__c) {
                sop.Reference_Number__c = newRec.Reference_Number__c;
                needsUpdate = true;
            }
            if (sop.Application__c != newRec.Application__c) {
                sop.Application__c = newRec.Application__c;
                needsUpdate = true;
            }
            if (sop.Sample_Sent_to_Unit__c != newRec.Sample_Sent_to_Unit__c) {
                sop.Sample_Sent_to_Unit__c = newRec.Sample_Sent_to_Unit__c;
                needsUpdate = true;
            }
            if (sop.Tracking_Number__c != newRec.Tracking_Number__c) {
                sop.Tracking_Number__c = newRec.Tracking_Number__c;
                needsUpdate = true;
            }
            if (sop.Packets__c != newRec.Packets__c) {
                sop.Packets__c = newRec.Packets__c;
                needsUpdate = true;
            }
            if (sop.New_Product__c != newRec.New_Product__c) {
                sop.New_Product__c = newRec.New_Product__c;
                needsUpdate = true;
            }
            if (sop.New_Product_Name__c != newRec.New_Product_Name__c) {
                sop.New_Product_Name__c = newRec.New_Product_Name__c;
                needsUpdate = true;
            }
            if (sop.New_Product_CI_No__c != newRec.New_Product_CI_No__c) {
                sop.New_Product_CI_No__c = newRec.New_Product_CI_No__c;
                needsUpdate = true;
            }

            if (needsUpdate) {
                updates.add(sop);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
    
    
    public static void updateSampleOutRequestStatus(Map<Id, Sample_Out__c> newMap, Map<Id, Sample_Out__c> oldMap) {
        Set<Id> requestIds = new Set<Id>();

        if (newMap != null) {
            for (Sample_Out__c sample : newMap.values()) {
                if (sample.Sample_Out_Request__c != null) {
                    requestIds.add(sample.Sample_Out_Request__c);
                }
            }
        }

        if (oldMap != null) {
            for (Sample_Out__c sample : oldMap.values()) {
                if (sample.Sample_Out_Request__c != null) {
                    requestIds.add(sample.Sample_Out_Request__c);
                }
            }
        }

        updateSampleOutRequestStatusByRequestIds(requestIds);
    }

    public static void updateSampleOutRequestStatusByRequestIds(Set<Id> requestIds) {
        if (requestIds == null || requestIds.isEmpty()) return;

        Map<Id, List<Sample_Out__c>> requestToSamplesMap = new Map<Id, List<Sample_Out__c>>();
        for (Sample_Out__c sample : [
            SELECT Id, Sample_Out_Request__c, Sample_Out_Status__c
            FROM Sample_Out__c
            WHERE Sample_Out_Request__c IN :requestIds
        ]) {
            if (!requestToSamplesMap.containsKey(sample.Sample_Out_Request__c)) {
                requestToSamplesMap.put(sample.Sample_Out_Request__c, new List<Sample_Out__c>());
            }
            requestToSamplesMap.get(sample.Sample_Out_Request__c).add(sample);
        }

        List<Sample_Out_Request__c> requestsToUpdate = new List<Sample_Out_Request__c>();

        for (Id requestId : requestToSamplesMap.keySet()) {
            List<Sample_Out__c> samples = requestToSamplesMap.get(requestId);
            Set<String> statuses = new Set<String>();

            for (Sample_Out__c sample : samples) {
                if (sample.Sample_Out_Status__c != null) {
                    statuses.add(sample.Sample_Out_Status__c);
                }
            }

            Sample_Out_Request__c request = new Sample_Out_Request__c(Id = requestId);

            Boolean allApproved = statuses.size() == 1 && statuses.contains('Sample Approved');
            Boolean allRejected = statuses.size() == 1 && statuses.contains('Sample Rejected');

            if (allApproved) {
                request.Sample_Request_Status__c = 'Approved';
                requestsToUpdate.add(request);
            } else if (allRejected) {
                request.Sample_Request_Status__c = 'Rejected';
                requestsToUpdate.add(request);
            } /*else {
                request.Sample_Request_Status__c = 'Sample Request';
            }

            requestsToUpdate.add(request);*/
        }

        if (!requestsToUpdate.isEmpty()) {
            update requestsToUpdate;
        }
    }
    
    public static void handleReSamplingEmail(List<Sample_Out__c> newList, Map<Id, Sample_Out__c> oldMap) {
        List<Id> sampleIdsToQuery = new List<Id>();

        for (Sample_Out__c newRec : newList) {
            Sample_Out__c oldRec = oldMap.get(newRec.Id);
            if (newRec.Sample_Out_Status__c == 'Re-Sampling' && oldRec.Sample_Out_Status__c != 'Re-Sampling') {
                sampleIdsToQuery.add(newRec.Id);
            }
        }

        if (sampleIdsToQuery.isEmpty()) return;
        
        List<Sample_Out__c> sampleOuts = [
            SELECT Id, Sample_Sent_to_Unit__c, Name, Application__c, Product_Name__c, Product_Name__r.Name, Colour_Index_Name__c, Quality__c, Quantity__c, Sample_Out_Status__c,
            Sample_Out_Request__c, Sample_Out_Request__r.Name, Sample_Out_Request__r.Request_Date__c, Sample_Out_Request__r.Person__c, Sample_Out_Request__r.Person__r.Name, Re_Sampling_Comment__c,
            Sample_Sent_to_Unit__r.Name, Packets__c, Unit_of_Measure__c, New_Product__c, New_Product_Name__c, New_Product_CI_No__c, Product_Name__r.CI_no__c, Sample_Out_Request__r.Person__r.Email
            FROM Sample_Out__c
            WHERE Id IN :sampleIdsToQuery
        ];

        List<String> toAddresses = new List<String>();
        String emailBody = '';

       if (!sampleOuts.isEmpty()) {
           
           emailBody += 'Sample In Request No: ' + sampleOuts[0].Sample_Out_Request__r.Name + '<br/><br/>';
            emailBody += 'Reason for Re-Sampling: ' + (sampleOuts[0].Re_Sampling_Comment__c != null ? sampleOuts[0].Re_Sampling_Comment__c : 'N/A') + '<br/><br/>';
           
           // emailBody += 'Requested Product Records:<br/><br/>';
          //  emailBody += '---------------------------------<br/>';
            emailBody += 'Below are the Re-Sampling Product::<br/><br/>';
            emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
            emailBody += '<thead><tr style="background-color: #f2f2f2;"><th>Requested Product No</th><th>Factory</th><th>Request Date</th><th>Product Name</th><th>CI No</th><th>Marketing Person</th><th>Application</th><th>Quality</th><th>Quantity in Grams</th></tr></thead><tbody>';
            
            for (Sample_Out__c sampleOut : sampleOuts) {
                emailBody += '<tr>';
                emailBody += '<td>' + sampleOut.Name + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Sent_to_Unit__r.Name != null ? sampleOut.Sample_Sent_to_Unit__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Out_Request__r.Request_Date__c != null ? sampleOut.Sample_Out_Request__r.Request_Date__c.format() : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Product_Name__r.Name != null ? sampleOut.Product_Name__r.Name : (sampleOut.New_Product_Name__c != null ? sampleOut.New_Product_Name__c : '')) + '</td>';
                emailBody += '<td>' + (sampleOut.Product_Name__r.CI_no__c != null ? sampleOut.Product_Name__r.CI_no__c : (sampleOut.New_Product_CI_No__c != null ? sampleOut.New_Product_CI_No__c : '')) + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Out_Request__r.Person__r.Name != null ? sampleOut.Sample_Out_Request__r.Person__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Application__c != null ? sampleOut.Application__c : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Quality__c != null ? sampleOut.Quality__c : '') + '</td>';
                emailBody += '<td>' + sampleOut.Quantity__c + (sampleOut.Packets__c != null ? ' x ' + sampleOut.Packets__c : '') + '</td>';
                emailBody += '</tr>';
                
                // Collect email addresses
                if (sampleOut.Sample_Out_Request__r != null && sampleOut.Sample_Out_Request__r.Person__r.Email != null) {
                    toAddresses.add(sampleOut.Sample_Out_Request__r.Person__r.Email);
                }
            }
            
            emailBody += '</tbody></table><br/><br/>';
        }

        emailBody += '</tbody></table>';

        if (!toAddresses.isEmpty()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Re-Sampling Notification for Requested Sample');
            mail.setHtmlBody(emailBody);
            mail.setToAddresses(toAddresses);
            mail.setWhatId(sampleOuts[0].Id);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
    
      public static void captureStatusChangeDates(List<Sample_Out_Request__c> newList, Map<Id, Sample_Out_Request__c> oldMap) {
        Date today = Date.today();

        for (Sample_Out_Request__c req : newList) {
            Sample_Out_Request__c oldRec = (oldMap != null && oldMap.containsKey(req.Id)) ? oldMap.get(req.Id) : null;

            // Only capture date if status is changed or new record
            if (oldRec == null || oldRec.Sample_Request_Status__c != req.Sample_Request_Status__c) {
                switch on req.Sample_Request_Status__c {
                    when 'Sample Request' {
                        if (req.Sample_Request_Capture_Date__c == null) {
                            req.Sample_Request_Capture_Date__c = today;
                        }
                    }
                    when 'Sample Request From Factory' {
                        if (req.Sample_RequestFrom_Factory_Capture_Date__c == null) {
                            req.Sample_RequestFrom_Factory_Capture_Date__c = today;
                        }
                    }
                    when 'Sample Sent to HO' {
                        if (req.Sample_Sent_to_Ho__c == null) {
                            req.Sample_Sent_to_Ho__c = today;
                        }
                    }
                    when 'In Progress' {
                        if (req.In_progress_Capture_Date__c == null) {
                            req.In_progress_Capture_Date__c = today;
                        }
                    }
                    when 'Approved' {
                        if (req.Approved_Capture_Date__c == null) {
                            req.Approved_Capture_Date__c = today;
                        }
                    }
                    when 'Rejected' {
                        if (req.Rejected_Capture_Date__c == null) {
                            req.Rejected_Capture_Date__c = today;
                        }
                    }
                }
            }
        }
    }
}