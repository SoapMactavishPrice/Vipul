public class SampleOutProductTriggerHandler {

    public static void updateSampleInStatus(List<Sample_Out_Products__c> newList, Map<Id, Sample_Out_Products__c> oldMap) {
        Map<String, String> statusMapping = new Map<String, String>{
            'Sample Sent to Customer' => 'Sample Sent to Customer',
            'Under Evaluation'        => 'Under Evaluation',
            'On Hold'                 => 'On Hold',
            'Sample Approved'         => 'Approved',
            'Sample Rejected'         => 'Rejected'
        };

        Map<Id, String> sampleInToUpdate = new Map<Id, String>();

        for (Sample_Out_Products__c newRec : newList) {
            Sample_Out_Products__c oldRec = oldMap.get(newRec.Id);

            if (newRec.Sample_Out_Status__c != oldRec.Sample_Out_Status__c &&
                newRec.Sample_In_Product__c != null &&
                statusMapping.containsKey(newRec.Sample_Out_Status__c)) {

                sampleInToUpdate.put(newRec.Sample_In_Product__c, statusMapping.get(newRec.Sample_Out_Status__c));
            }
        }

        if (!sampleInToUpdate.isEmpty()) {
            List<Sample_In__c> sampleInUpdates = new List<Sample_In__c>();

            for (Id sampleInId : sampleInToUpdate.keySet()) {
                sampleInUpdates.add(new Sample_In__c(
                    Id = sampleInId,
                    Sample_In_Status__c = sampleInToUpdate.get(sampleInId)
                ));
            }

            update sampleInUpdates;
        }
    }

	public static void updateSampleOutStatus(List<Sample_Out_Products__c> newList, Map<Id, Sample_Out_Products__c> oldMap) {
        Map<String, String> statusMapping = new Map<String, String>{
            'Sample Sent to Customer' => 'Sample Sent to Customer',
            'Under Evaluation'        => 'Under Evaluation',
            'On Hold'                 => 'On Hold',
            'Sample Approved'         => 'Sample Approved',
            'Sample Rejected'         => 'Sample Rejected'
        };

        Map<Id, String> sampleInToUpdate = new Map<Id, String>();

        for (Sample_Out_Products__c newRec : newList) {
            Sample_Out_Products__c oldRec = oldMap.get(newRec.Id);

            if (newRec.Sample_Out_Status__c != oldRec.Sample_Out_Status__c &&
                newRec.Requested_Product__c != null &&
                statusMapping.containsKey(newRec.Sample_Out_Status__c)) {

                sampleInToUpdate.put(newRec.Requested_Product__c, statusMapping.get(newRec.Sample_Out_Status__c));
            }
        }

        if (!sampleInToUpdate.isEmpty()) {
            List<Sample_Out__c> sampleInUpdates = new List<Sample_Out__c>();

            for (Id sampleInId : sampleInToUpdate.keySet()) {
                sampleInUpdates.add(new Sample_Out__c(
                    Id = sampleInId,
                    Sample_Out_Status__c = sampleInToUpdate.get(sampleInId)
                ));
            }

            update sampleInUpdates;
        }
    }
    
    public static void populateFieldsFromPreviousSampleOut(List<Sample_Out_Products__c> newList) {
        Set<Id> sampleInIds = new Set<Id>();

        for (Sample_Out_Products__c newRec : newList) {
            if (newRec.Sample_In_Product__c != null) {
                sampleInIds.add(newRec.Sample_In_Product__c);
            }
        }

        if (sampleInIds.isEmpty()) return;

        // Fetch the most recent Sample_Out_Products__c per Sample_In__c
        Map<Id, Sample_Out_Products__c> latestSampleOutMap = new Map<Id, Sample_Out_Products__c>();
        for (AggregateResult ar : [
            SELECT Sample_In_Product__c sampleInId, MAX(CreatedDate) maxDate
            FROM Sample_Out_Products__c
            WHERE Sample_In_Product__c IN :sampleInIds
            GROUP BY Sample_In_Product__c
        ]) {
            latestSampleOutMap.put((Id)ar.get('sampleInId'), null);
        }

        // Now fetch the actual records with those max dates
        List<Sample_Out_Products__c> latestRecords = [
            SELECT Id, Sample_In_Product__c, Product__c, Quantity__c, Reference_Number__c, Customer_s_Product_Name__c,
                   Application__c, Sample_Sent_to_Unit__c, Tracking_Number__c, Sample_Out_Status__c, CreatedDate, Customer_Reference_No__c
            FROM Sample_Out_Products__c
            WHERE Sample_In_Product__c IN :sampleInIds
            ORDER BY CreatedDate DESC
        ];

        for (Sample_Out_Products__c rec : latestRecords) {
            if (!latestSampleOutMap.containsKey(rec.Sample_In_Product__c) || latestSampleOutMap.get(rec.Sample_In_Product__c) == null) {
                latestSampleOutMap.put(rec.Sample_In_Product__c, rec);
            }
        }

        for (Sample_Out_Products__c newRec : newList) {
            Sample_Out_Products__c previous = latestSampleOutMap.get(newRec.Sample_In_Product__c);
            if (previous != null) {
                newRec.Product__c = previous.Product__c;
                newRec.Quantity__c = previous.Quantity__c;
                newRec.Customer_s_Product_Name__c = previous.Customer_s_Product_Name__c;
                newRec.Application__c = previous.Application__c;
                newRec.Sample_Sent_to_Unit__c = previous.Sample_Sent_to_Unit__c;
                newRec.Tracking_Number__c = previous.Tracking_Number__c;
                newRec.Sample_Out_Status__c = 'Sample Sent to Customer';
                newRec.Customer_Reference_No__c = previous.Customer_Reference_No__c;
            }
        }
    }
    
    public static void syncFieldsToSampleIn(List<Sample_Out_Products__c> newList, Map<Id, Sample_Out_Products__c> oldMap) {
        Map<Id, Sample_In__c> updates = new Map<Id, Sample_In__c>();
        
        for (Sample_Out_Products__c newRec : newList) {
            Sample_Out_Products__c oldRec = oldMap.get(newRec.Id);
            
            if (newRec.Sample_In_Product__c == null) continue;
            
            Boolean hasChanged = false;
            Sample_In__c updateRec = new Sample_In__c(Id = newRec.Sample_In_Product__c);
            
            if (newRec.Product__c != oldRec.Product__c) {
                updateRec.VOL_Product_Name__c = newRec.Product__c;
                hasChanged = true;
            }
            if (newRec.Quantity__c != oldRec.Quantity__c) {
                updateRec.Quantity__c = newRec.Quantity__c;
                hasChanged = true;
            }
            if (newRec.Application__c != oldRec.Application__c) {
                updateRec.Application__c = newRec.Application__c;
                hasChanged = true;
            }
            if (newRec.Sample_Sent_to_Unit__c != oldRec.Sample_Sent_to_Unit__c) {
                updateRec.Sample_Sent_to_Unit__c = newRec.Sample_Sent_to_Unit__c;
                hasChanged = true;
            }
            if (newRec.Tracking_Number__c != oldRec.Tracking_Number__c) {
                updateRec.Courier_Tracking_No__c = newRec.Tracking_Number__c;
                hasChanged = true;
            }
            //if (newRec.Reference_Number__c != oldRec.Reference_Number__c) {
                updateRec.Sample_Out_Ref_No__c = newRec.Reference_Number__c;
                hasChanged = true;
            //}
            
            if (hasChanged) {
                updates.put(updateRec.Id, updateRec);
            }
        }
        
        if (!updates.isEmpty()) {
            update updates.values();
        }
    }
    
    public static void populateFieldsFromPreviousSampleOutForOut(List<Sample_Out_Products__c> newRecords) {
        Set<Id> requestedProductIds = new Set<Id>();

        for (Sample_Out_Products__c sop : newRecords) {
            if (sop.Requested_Product__c != null) {
                requestedProductIds.add(sop.Requested_Product__c);
            }
        }

        if (requestedProductIds.isEmpty()) return;

        // Step 1: Get the most recent Sample_Out_Products__c record per Requested_Product__c
        Map<Id, Sample_Out_Products__c> latestSampleOutMap = new Map<Id, Sample_Out_Products__c>();

        List<Sample_Out_Products__c> latestRecords = [
            SELECT Id, Requested_Product__c, Product__c, Quantity__c, Reference_Number__c,
                   Application__c, Sample_Sent_to_Unit__c, Tracking_Number__c,
                   Sample_Out_Status__c, Packets__c, New_Product__c, Quality__c,
                   New_Product_Name__c, New_Product_CI_No__c, CreatedDate
            FROM Sample_Out_Products__c
            WHERE Requested_Product__c IN :requestedProductIds
            ORDER BY CreatedDate DESC
        ];

        for (Sample_Out_Products__c record : latestRecords) {
            if (!latestSampleOutMap.containsKey(record.Requested_Product__c)) {
                latestSampleOutMap.put(record.Requested_Product__c, record);
            }
        }

        // Step 2: Copy values from the latest record to the new one
        for (Sample_Out_Products__c newRecord : newRecords) {
            if (newRecord.Requested_Product__c != null &&
                latestSampleOutMap.containsKey(newRecord.Requested_Product__c)) {

                Sample_Out_Products__c existing = latestSampleOutMap.get(newRecord.Requested_Product__c);
                if (existing != null) {
                    newRecord.Product__c = existing.Product__c;
                    newRecord.Quantity__c = existing.Quantity__c;
                    newRecord.Quality__c = existing.Quality__c;
                    newRecord.Application__c = existing.Application__c;
                    newRecord.Sample_Sent_to_Unit__c = existing.Sample_Sent_to_Unit__c;
                    newRecord.Tracking_Number__c = existing.Tracking_Number__c;
                    newRecord.Sample_Out_Status__c = 'Sample Sent to Customer';
                    newRecord.Packets__c = existing.Packets__c;
                    newRecord.New_Product__c = existing.New_Product__c;
                    newRecord.New_Product_Name__c = existing.New_Product_Name__c;
                    newRecord.New_Product_CI_No__c = existing.New_Product_CI_No__c;
                }
            }
        }
    }
    
    public static void syncToSampleOut(List<Sample_Out_Products__c> updatedRecords) {
        Map<Id, Sample_Out_Products__c> sopBySampleOutId = new Map<Id, Sample_Out_Products__c>();
        
        for (Sample_Out_Products__c sop : updatedRecords) {
            if (sop.Requested_Product__c != null) {
                sopBySampleOutId.put(sop.Requested_Product__c, sop);
            }
        }
        
        if (sopBySampleOutId.isEmpty()) return;
        
        // Fetch related Sample_Out__c records
        Map<Id, Sample_Out__c> relatedSampleOuts = new Map<Id, Sample_Out__c>(
            [SELECT Id, Product_Name__c, Quantity__c, Reference_Number__c, Application__c,
             Sample_Sent_to_Unit__c, Tracking_Number__c, Sample_Out_Status__c, Quality__c,
             Packets__c, New_Product__c, New_Product_Name__c, New_Product_CI_No__c
             FROM Sample_Out__c
             WHERE Id IN :sopBySampleOutId.keySet()]
        );
        
        List<Sample_Out__c> sampleOutsToUpdate = new List<Sample_Out__c>();
        
        for (Id sampleOutId : sopBySampleOutId.keySet()) {
            Sample_Out_Products__c sop = sopBySampleOutId.get(sampleOutId);
            Sample_Out__c so = relatedSampleOuts.get(sampleOutId);
            
            if (so == null) continue;
            
            Boolean needsUpdate = false;
            
            if (so.Product_Name__c != sop.Product__c) {
                so.Product_Name__c = sop.Product__c;
                needsUpdate = true;
            }
            if (so.Quantity__c != sop.Quantity__c) {
                so.Quantity__c = sop.Quantity__c;
                needsUpdate = true;
            }
            if (so.Quality__c != sop.Quality__c) {
                so.Quality__c = sop.Quality__c;
                needsUpdate = true;
            }
            if (so.Reference_Number__c != sop.Reference_Number__c) {
                so.Reference_Number__c = sop.Reference_Number__c;
                needsUpdate = true;
            }
            if (so.Application__c != sop.Application__c) {
                so.Application__c = sop.Application__c;
                needsUpdate = true;
            }
            if (so.Sample_Sent_to_Unit__c != sop.Sample_Sent_to_Unit__c) {
                so.Sample_Sent_to_Unit__c = sop.Sample_Sent_to_Unit__c;
                needsUpdate = true;
            }
            if (so.Tracking_Number__c != sop.Tracking_Number__c) {
                so.Tracking_Number__c = sop.Tracking_Number__c;
                needsUpdate = true;
            }
            if (so.Sample_Out_Status__c != sop.Sample_Out_Status__c) {
                so.Sample_Out_Status__c = sop.Sample_Out_Status__c;
                needsUpdate = true;
            }
            if (so.Packets__c != sop.Packets__c) {
                so.Packets__c = sop.Packets__c;
                needsUpdate = true;
            }
            if (so.New_Product__c != sop.New_Product__c) {
                so.New_Product__c = sop.New_Product__c;
                needsUpdate = true;
            }
            if (so.New_Product_Name__c != sop.New_Product_Name__c) {
                so.New_Product_Name__c = sop.New_Product_Name__c;
                needsUpdate = true;
            }
            if (so.New_Product_CI_No__c != sop.New_Product_CI_No__c) {
                so.New_Product_CI_No__c = sop.New_Product_CI_No__c;
                needsUpdate = true;
            }
            
            	//so.Reference_Number__c = sop.Reference_Number__c;
                //needsUpdate = true;
            
            if (needsUpdate) {
                sampleOutsToUpdate.add(so);
            }
        }
        
        if (!sampleOutsToUpdate.isEmpty()) {
            update sampleOutsToUpdate;
        }
    }


}