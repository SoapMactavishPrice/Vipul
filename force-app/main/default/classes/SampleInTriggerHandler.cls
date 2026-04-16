public class SampleInTriggerHandler {
    
    public static void handleAfterInsertOrUpdate(List<Sample_In__c> newSamples) {
        List<Product2> productsToInsert = new List<Product2>();
        Map<Id, Sample_In__c> sampleToUpdateMap = new Map<Id, Sample_In__c>();
        Map<Id, String> sampleToProductNameMap = new Map<Id, String>();

        for (Sample_In__c sample : newSamples) {
            if (sample.New_Product_Development__c && String.isNotBlank(sample.New_Development__c) && sample.VOL_Product_Name__c == null) {
                productsToInsert.add(new Product2(
                    Name = sample.New_Development__c,
                    IsActive = true,
                    CurrencyIsoCode = sample.CurrencyIsoCode
                ));
                sampleToUpdateMap.put(sample.Id, sample);
                sampleToProductNameMap.put(sample.Id, sample.New_Development__c);
            } else if (sample.R_D__c && String.isNotBlank(sample.R_D_Product_Development__c) && sample.VOL_Product_Name__c == null) {
                productsToInsert.add(new Product2(
                    Name = sample.R_D_Product_Development__c,
                    IsActive = true,
                    CurrencyIsoCode = sample.CurrencyIsoCode
                ));
                sampleToUpdateMap.put(sample.Id, sample);
                sampleToProductNameMap.put(sample.Id, sample.R_D_Product_Development__c);
            }
        }

        if (productsToInsert.isEmpty()) return;

        insert productsToInsert;

        Id standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        Map<String, Id> productNameToId = new Map<String, Id>();

        for (Product2 prod : productsToInsert) {
            productNameToId.put(prod.Name, prod.Id);
            pricebookEntries.add(new PricebookEntry(
                Product2Id = prod.Id,
                Pricebook2Id = standardPricebookId,
                UnitPrice = 1,
                IsActive = true,
                CurrencyIsoCode = prod.CurrencyIsoCode
            ));
        }

        insert pricebookEntries;

        List<Sample_In__c> samplesToUpdate = new List<Sample_In__c>();
        for (Id sampleId : sampleToUpdateMap.keySet()) {
            Sample_In__c sample = sampleToUpdateMap.get(sampleId);
            String productName = sampleToProductNameMap.get(sampleId);
            Id productId = productNameToId.get(productName);
            if (productId != null) {
                samplesToUpdate.add(new Sample_In__c(
                    Id = sample.Id,
                    VOL_Product_Name__c = productId
                ));
            }
        }

        if (!samplesToUpdate.isEmpty()) {
            update samplesToUpdate;
        }
    }
    
    public static void createSampleOutRecordsOnce(List<Sample_In__c> sampleInList) {
        Map<Id, Sample_In__c> validSampleInMap = new Map<Id, Sample_In__c>();

        for (Sample_In__c sampleIn : sampleInList) {
            if (sampleIn.VOL_Product_Name__c != null &&
                sampleIn.Sample_In_Status__c == 'Sample Sent to Customer') {
                validSampleInMap.put(sampleIn.Id, sampleIn);
            }
        }

        if (validSampleInMap.isEmpty()) return;

        // Query existing Sample_Out_Products__c records to avoid duplicates
        Set<Id> alreadyCreatedSampleInIds = new Set<Id>();
        for (Sample_Out_Products__c sampleOut : [
            SELECT Id, Sample_In_Product__c
            FROM Sample_Out_Products__c
            WHERE Sample_In_Product__c IN :validSampleInMap.keySet()
        ]) {
            alreadyCreatedSampleInIds.add(sampleOut.Sample_In_Product__c);
        }

        List<Sample_Out_Products__c> toInsert = new List<Sample_Out_Products__c>();

        for (Sample_In__c sampleIn : validSampleInMap.values()) {
            if (!alreadyCreatedSampleInIds.contains(sampleIn.Id)) {
                Sample_Out_Products__c newSampleOut = new Sample_Out_Products__c();
                newSampleOut.Sample_In_Product__c = sampleIn.Id;
                newSampleOut.Product__c = sampleIn.VOL_Product_Name__c;
                newSampleOut.Quantity__c = sampleIn.Quantity__c;
                newSampleOut.Reference_Number__c = sampleIn.Sample_Out_Ref_No__c;
                newSampleOut.Application__c = sampleIn.Application__c;
                newSampleOut.Sample_Sent_to_Unit__c = sampleIn.Sample_Sent_to_Unit__c;
                newSampleOut.Tracking_Number__c = sampleIn.Courier_Tracking_No__c;
                newSampleOut.Sample_Out_Status__c = 'Sample Sent to Customer';
                newSampleOut.Customer_s_Product_Name__c = sampleIn.Customer_s_Product_Name__c;
                newSampleOut.Customer_Reference_No__c = sampleIn.Customer_Reference_No__c;
                newSampleOut.Company_Name__c = sampleIn.Company_Name__c;
                toInsert.add(newSampleOut);
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }
    
    
    public static void syncStatusToSampleOut(List<Sample_In__c> newList, Map<Id, Sample_In__c> oldMap) {
        Map<String, String> reverseStatusMapping = new Map<String, String>{
            'Sample Sent to Customer' => 'Sample Sent to Customer',
            'Under Evaluation'        => 'Under Evaluation',
            'On Hold'                 => 'On Hold',
            'Approved'                => 'Sample Approved',
            'Rejected'                => 'Sample Rejected'
        };

        Set<Id> sampleInIdsToUpdate = new Set<Id>();

        for (Sample_In__c newRec : newList) {
            Sample_In__c oldRec = oldMap.get(newRec.Id);

            Boolean statusChanged = newRec.Sample_In_Status__c != oldRec.Sample_In_Status__c &&
                                    reverseStatusMapping.containsKey(newRec.Sample_In_Status__c);

            Boolean fieldChanged =
                newRec.VOL_Product_Name__c != oldRec.VOL_Product_Name__c ||
                newRec.Quantity__c != oldRec.Quantity__c ||
                newRec.Sample_Out_Ref_No__c != oldRec.Sample_Out_Ref_No__c ||
                newRec.Application__c != oldRec.Application__c ||
                newRec.Sample_Sent_to_Unit__c != oldRec.Sample_Sent_to_Unit__c ||
                newRec.Courier_Tracking_No__c != oldRec.Courier_Tracking_No__c;

            if (statusChanged || fieldChanged) {
                sampleInIdsToUpdate.add(newRec.Id);
            }
        }

        if (sampleInIdsToUpdate.isEmpty()) return;

        // Fetch latest Sample_Out_Products__c per Sample_In__c
        List<Sample_Out_Products__c> allRelated = [
            SELECT Id, Sample_In_Product__c
            FROM Sample_Out_Products__c
            WHERE Sample_In_Product__c IN :sampleInIdsToUpdate
            ORDER BY CreatedDate DESC
        ];

        Map<Id, Sample_Out_Products__c> latestSampleOutMap = new Map<Id, Sample_Out_Products__c>();
        for (Sample_Out_Products__c sop : allRelated) {
            if (!latestSampleOutMap.containsKey(sop.Sample_In_Product__c)) {
                latestSampleOutMap.put(sop.Sample_In_Product__c, sop);
            }
        }

        List<Sample_Out_Products__c> updates = new List<Sample_Out_Products__c>();

        for (Sample_In__c newRec : newList) {
            if (!latestSampleOutMap.containsKey(newRec.Id)) continue;

            Sample_Out_Products__c sop = latestSampleOutMap.get(newRec.Id);
            Sample_In__c oldRec = oldMap.get(newRec.Id);

            Boolean shouldUpdate = false;

            if (newRec.Sample_In_Status__c != oldRec.Sample_In_Status__c &&
                reverseStatusMapping.containsKey(newRec.Sample_In_Status__c)) {
                sop.Sample_Out_Status__c = reverseStatusMapping.get(newRec.Sample_In_Status__c);
                shouldUpdate = true;
            }

            if (newRec.VOL_Product_Name__c != oldRec.VOL_Product_Name__c) {
                sop.Product__c = newRec.VOL_Product_Name__c;
                shouldUpdate = true;
            }
            if (newRec.Quantity__c != oldRec.Quantity__c) {
                sop.Quantity__c = newRec.Quantity__c;
                shouldUpdate = true;
            }
            if (newRec.Sample_Out_Ref_No__c != oldRec.Sample_Out_Ref_No__c) {
                sop.Reference_Number__c = newRec.Sample_Out_Ref_No__c;
                shouldUpdate = true;
            }
            if (newRec.Application__c != oldRec.Application__c) {
                sop.Application__c = newRec.Application__c;
                shouldUpdate = true;
            }
            if (newRec.Sample_Sent_to_Unit__c != oldRec.Sample_Sent_to_Unit__c) {
                sop.Sample_Sent_to_Unit__c = newRec.Sample_Sent_to_Unit__c;
                shouldUpdate = true;
            }
            if (newRec.Courier_Tracking_No__c != oldRec.Courier_Tracking_No__c) {
                sop.Tracking_Number__c = newRec.Courier_Tracking_No__c;
                shouldUpdate = true;
            }

            if (shouldUpdate) {
                updates.add(sop);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }


   /* public static void captureStatusChangeDates(List<Sample_In__c> newList, Map<Id, Sample_In__c> oldMap) {
        for (Sample_In__c newRec : newList) {
            Sample_In__c oldRec = oldMap.get(newRec.Id);

            if (oldRec.Sample_In_Status__c != newRec.Sample_In_Status__c) {
                String newStatus = newRec.Sample_In_Status__c;

                Date today = Date.today();

                if (newStatus == 'Sample Sent to Factory' && newRec.Sample_Sent_to_Factory_Date__c == null) {
                    newRec.Sample_Sent_to_Factory_Date__c = today;
                } else if (newStatus == 'Sample Sent to Customer' && newRec.Sample_Sent_to_Customer_Date__c == null) {
                    newRec.Sample_Sent_to_Customer_Date__c = today;
                } else if (newStatus == 'Sample Matching' && newRec.Sample_Matching_Date__c == null) {
                    newRec.Sample_Matching_Date__c = today;
                } else if (newStatus == 'Sample Sent to HO' && newRec.Sample_Sent_to_HO_Date__c == null) {
                    newRec.Sample_Sent_to_HO_Date__c = today;
                } else if (newStatus == 'Rejected' && newRec.Sample_Rejected_Date__c == null) {
                    newRec.Sample_Rejected_Date__c = today;
                } else if (newStatus == 'Approved' && newRec.Sample_Approved_Date__c == null) {
                    newRec.Sample_Approved_Date__c = today;
                }
            }
        }
    }  */
    
    public static void captureStatusChangeDates(
    List<Sample_In__c> newList,
    Map<Id, Sample_In__c> oldMap
) {
    Date today = Date.today();

    for (Sample_In__c newRec : newList) {

        Sample_In__c oldRec =
            oldMap != null ? oldMap.get(newRec.Id) : null;

        Boolean statusChanged =
            oldRec == null ||
            newRec.Sample_In_Status__c != oldRec.Sample_In_Status__c;

        if (!statusChanged || newRec.Sample_In_Status__c == null) {
            continue;
        }

        switch on newRec.Sample_In_Status__c {

            when 'Sample Received from Customer' {
                if (newRec.Sample_Received_from_Customer_Date__c == null)
                    newRec.Sample_Received_from_Customer_Date__c = today;
            }

            when 'Sample Sent to Factory' {
                if (newRec.Sample_Sent_to_Factory_Date__c == null)
                    newRec.Sample_Sent_to_Factory_Date__c = today;
            }

            when 'Sample Matching' {
                if (newRec.Sample_Matching_Date__c == null)
                    newRec.Sample_Matching_Date__c = today;
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

            when 'Rejected' {
                if (newRec.Sample_Rejected_Date__c == null)
                    newRec.Sample_Rejected_Date__c = today;
            }

            when 'Approved' {
                if (newRec.Sample_Approved_Date__c == null)
                    newRec.Sample_Approved_Date__c = today;
            }
        }
    }
}

    
    public static void populateFieldsFromRequest(List<Sample_In__c> sampleInList) {
        Set<Id> requestIds = new Set<Id>();

        // Collect all Sample_In_Request__c IDs
        for (Sample_In__c so : sampleInList) {
            if (so.Sample_In_Request__c != null) {
                requestIds.add(so.Sample_In_Request__c);
            }
        }

        // Query related Sample_In_Request__c records
        Map<Id, Sample_In_Request__c> requestMap = new Map<Id, Sample_In_Request__c>(
            [SELECT Id, Country__c, Company_Name__c FROM Sample_In_Request__c WHERE Id IN :requestIds]
        );

        // Populate fields on Sample_In__c
        for (Sample_In__c so : sampleInList) {
            if (so.Sample_In_Request__c != null && requestMap.containsKey(so.Sample_In_Request__c)) {
                Sample_In_Request__c relatedRequest = requestMap.get(so.Sample_In_Request__c);
                so.Country__c = relatedRequest.Country__c;
                so.Company_Name__c = relatedRequest.Company_Name__c;
            }
        }
    }
    
    public static void updateSampleInRequestStatus(Map<Id, Sample_In__c> newMap, Map<Id, Sample_In__c> oldMap) {
        Set<Id> requestIds = new Set<Id>();

        if (newMap != null) {
            for (Sample_In__c sample : newMap.values()) {
                if (sample.Sample_In_Request__c != null) {
                    requestIds.add(sample.Sample_In_Request__c);
                }
            }
        }

        if (oldMap != null) {
            for (Sample_In__c sample : oldMap.values()) {
                if (sample.Sample_In_Request__c != null) {
                    requestIds.add(sample.Sample_In_Request__c);
                }
            }
        }

        updateSampleInRequestStatusByRequestIds(requestIds);
    }

    public static void updateSampleInRequestStatusByRequestIds(Set<Id> requestIds) {
        if (requestIds == null || requestIds.isEmpty()) return;

        Map<Id, List<Sample_In__c>> requestToSamplesMap = new Map<Id, List<Sample_In__c>>();
        for (Sample_In__c sample : [
            SELECT Id, Sample_In_Request__c, Sample_In_Status__c
            FROM Sample_In__c
            WHERE Sample_In_Request__c IN :requestIds
        ]) {
            if (!requestToSamplesMap.containsKey(sample.Sample_In_Request__c)) {
                requestToSamplesMap.put(sample.Sample_In_Request__c, new List<Sample_In__c>());
            }
            requestToSamplesMap.get(sample.Sample_In_Request__c).add(sample);
        }

        List<Sample_In_Request__c> requestsToUpdate = new List<Sample_In_Request__c>();

        for (Id requestId : requestToSamplesMap.keySet()) {
            List<Sample_In__c> samples = requestToSamplesMap.get(requestId);
            Set<String> statuses = new Set<String>();

            for (Sample_In__c sample : samples) {
                if (sample.Sample_In_Status__c != null) {
                    statuses.add(sample.Sample_In_Status__c);
                }
            }

            Sample_In_Request__c request = new Sample_In_Request__c(Id = requestId);

            Boolean allApproved = statuses.size() == 1 && statuses.contains('Approved');
            Boolean allRejected = statuses.size() == 1 && statuses.contains('Rejected');

            if (allApproved) {
                request.Sample_In_Status__c = 'Approved';
                requestsToUpdate.add(request);
            } else if (allRejected) {
                request.Sample_In_Status__c = 'Rejected';
                requestsToUpdate.add(request);
            } /*else {
                request.Sample_In_Status__c = 'Sample In';
            }

            requestsToUpdate.add(request);*/
        }

        if (!requestsToUpdate.isEmpty()) {
            update requestsToUpdate;
        }
    }
    
    public static void handleReSamplingEmail(List<Sample_In__c> newList, Map<Id, Sample_In__c> oldMap) {
        List<Id> sampleIdsToQuery = new List<Id>();

        for (Sample_In__c newRec : newList) {
            Sample_In__c oldRec = oldMap.get(newRec.Id);
            if (newRec.Sample_In_Status__c == 'Re-Sampling' && oldRec.Sample_In_Status__c != 'Re-Sampling') {
                sampleIdsToQuery.add(newRec.Id);
            }
        }

        if (sampleIdsToQuery.isEmpty()) return;

        List<Sample_In__c> sampleIns = [
            SELECT Id, Name, Sample_In_Status__c, Sample_Sent_to_Unit__r.Name, Customer_s_Product_Name__c, C_I__c,
                   Customer_Reference_No__c, S_In_Ref_No__c, Quantity__c, Sample_In_Request__r.Person__r.Name,
                   Application__c, Sample_In_Request__r.Name, Marketing_Person__r.Email, Re_Sampling_Comment__c
            FROM Sample_In__c
            WHERE Id IN :sampleIdsToQuery
        ];

        List<String> toAddresses = new List<String>();
        String emailBody = '';

        // Assuming all records have the same Sample_In_Request__r.Name
        if (!sampleIns.isEmpty()) {
            emailBody += 'Sample In Request No: ' + sampleIns[0].Sample_In_Request__r.Name + '<br/><br/>';
            emailBody += 'Reason for Re-Sampling: ' + (sampleIns[0].Re_Sampling_Comment__c != null ? sampleIns[0].Re_Sampling_Comment__c : 'N/A') + '<br/><br/>';
        }

        emailBody += 'Below are the Re-Sampling Product:<br/><br/>';
        emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        emailBody += '<thead><tr style="background-color: #f2f2f2;">';
        emailBody += '<th>S.In No</th><th>Factory</th><th>Product Name</th><th>CI No</th><th>Customer Ref No.</th>';
        emailBody += '<th>VOL In Ref No.</th><th>Qty in Grams</th><th>Marketing Person</th><th>Application</th>';
        emailBody += '</tr></thead><tbody>';

        for (Sample_In__c sample : sampleIns) {
            emailBody += '<tr>';
            emailBody += '<td>' + sample.Name + '</td>';
            emailBody += '<td>' + (sample.Sample_Sent_to_Unit__r != null ? sample.Sample_Sent_to_Unit__r.Name : '') + '</td>';
            emailBody += '<td>' + (sample.Customer_s_Product_Name__c != null ? sample.Customer_s_Product_Name__c : '') + '</td>';
            emailBody += '<td>' + (sample.C_I__c != null ? sample.C_I__c : '') + '</td>';
            emailBody += '<td>' + (sample.Customer_Reference_No__c != null ? sample.Customer_Reference_No__c : '') + '</td>';
            emailBody += '<td>' + (sample.S_In_Ref_No__c != null ? sample.S_In_Ref_No__c : '') + '</td>';
            emailBody += '<td>' + (sample.Quantity__c != null ? String.valueOf(sample.Quantity__c) : '') + '</td>';
            emailBody += '<td>' + (sample.Sample_In_Request__r != null && sample.Sample_In_Request__r.Person__r != null ? sample.Sample_In_Request__r.Person__r.Name : '') + '</td>';
            emailBody += '<td>' + (sample.Application__c != null ? sample.Application__c : '') + '</td>';
            emailBody += '</tr>';

            // Collect email addresses
            if (sample.Marketing_Person__r != null && sample.Marketing_Person__r.Email != null) {
                toAddresses.add(sample.Marketing_Person__r.Email);
            }
        }

        emailBody += '</tbody></table>';

        if (!toAddresses.isEmpty()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Re-Sampling Notification for Sample In Record');
            mail.setHtmlBody(emailBody);
            mail.setToAddresses(toAddresses);
            mail.setWhatId(sampleIns[0].Id);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
    
 
    
}