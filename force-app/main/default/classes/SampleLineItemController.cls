public class SampleLineItemController {

    // Method to fetch Sample Out records with all required fields
    @AuraEnabled(cacheable=true)
    public static List<Sample_Out__c> getSampleOuts(Id sampleRequestId) {
        return [
            SELECT 
            Id, 
            Sample_Request__c, 
            Product_Name__c, 
            Product_Name__r.Name,
            Quantity__c,
            Quality__c, 
            Colour_Index_Name__c,
            Packets__c,
            Application__c, 
            Unit_of_Measure__c,
            Sample_Sent_to_Unit__c,
            Sample_Sent_to_Unit__r.Name,
            Status__c,
            Comments__c,
            Reference_Number__c
            FROM Sample_Out__c 
            WHERE Sample_Request__c = :sampleRequestId
            ORDER BY CreatedDate
        ];
    }

    // Method to fetch Sample In records with all required fields
    @AuraEnabled(cacheable=true)
    public static List<Sample_In__c> getSampleIns(Id sampleRequestId) {
        return [
            SELECT 
                Id, 
                Sample_Request__c, 
                Customer_s_Product_Name__c, 
                Application__c, 
                Annual_Qty_of_Business__c, 
                Courier_Tracking_No_Date__c,
                C_I__c,
                S_In_Ref_No__c,
                VOL_Product_Name__c,
                VOL_Product_Name__r.Name,
                Sample_Sent_to_Unit__c,
                Sample_Sent_to_Unit__r.Name
            FROM Sample_In__c 
            WHERE Sample_Request__c = :sampleRequestId
            ORDER BY CreatedDate
        ];
    }

    // Method to update Sample Out records with validation
    @AuraEnabled
    public static void updateSampleOuts(List<Sample_Out__c> sampleOutRecords) {
        try {
            if (sampleOutRecords == null || sampleOutRecords.isEmpty()) {
                throw new AuraHandledException('No records provided for update');
            }
            
            // Prepare records for update with only necessary fields
            List<Sample_Out__c> recordsToUpdate = new List<Sample_Out__c>();
            for (Sample_Out__c record : sampleOutRecords) {
                recordsToUpdate.add(new Sample_Out__c(
                    Id = record.Id,
                    Quantity__c = record.Quantity__c,
                    Quality__c = record.Quality__c,
                    Colour_Index_Name__c = record.Colour_Index_Name__c,
                    Packets__c = record.Packets__c,
                    Application__c = record.Application__c,
                    Unit_of_Measure__c = record.Unit_of_Measure__c,
                    Sample_Sent_to_Unit__c = record.Sample_Sent_to_Unit__c,
                    Status__c = record.Status__c,
                    Comments__c = record.Comments__c,
                    Reference_Number__c = record.Reference_Number__c
                ));
            }
            
            update recordsToUpdate;
        } catch (DmlException e) {
            throw new AuraHandledException('Database error: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }

    // Method to update Sample In records with validation
    @AuraEnabled
    public static void updateSampleIns(List<Sample_In__c> sampleInRecords) {
        try {
            if (sampleInRecords == null || sampleInRecords.isEmpty()) {
                throw new AuraHandledException('No records provided for update');
            }
            
            // Prepare records for update with only necessary fields
            List<Sample_In__c> recordsToUpdate = new List<Sample_In__c>();
            for (Sample_In__c record : sampleInRecords) {
                recordsToUpdate.add(new Sample_In__c(
                    Id = record.Id,
                    C_I__c = record.C_I__c,
                    S_In_Ref_No__c = record.S_In_Ref_No__c,
                    Application__c = record.Application__c,
                    Annual_Qty_of_Business__c = record.Annual_Qty_of_Business__c,
                    Sample_Sent_to_Unit__c = record.Sample_Sent_to_Unit__c
                ));
            }
            
            update recordsToUpdate;
        } catch (DmlException e) {
            throw new AuraHandledException('Database error: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected error: ' + e.getMessage());
        }
    }

    // Method to get Unit of Measure picklist values
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getUnitOfMeasureOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Sample_Out__c.Unit_of_Measure__c.getDescribe();
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }
        return options;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getStatus() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Sample_Out__c.Status__c.getDescribe();
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new Map<String, String>{
                    'label' => entry.getLabel(),
                    'value' => entry.getValue()
                });
            }
        }
        return options;
    }

    // Method to search Unit Master records
    @AuraEnabled(cacheable=true)
    public static List<Unit_Master__c> searchUnits(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return new List<Unit_Master__c>();
        }
        
        String searchKey = '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%';
        return [
            SELECT 
                Id, 
                Name 
            FROM Unit_Master__c 
            WHERE Name LIKE :searchKey 
            ORDER BY Name 
            LIMIT 10
        ];
    }

    // Additional method to get Unit Master details if needed
    @AuraEnabled(cacheable=true)
    public static Unit_Master__c getUnitDetails(Id unitId) {
        return [
            SELECT 
                Id, 
                Name 
            FROM Unit_Master__c 
            WHERE Id = :unitId 
            LIMIT 1
        ];
    }
}