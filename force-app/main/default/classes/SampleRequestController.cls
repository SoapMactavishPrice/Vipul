public with sharing class SampleRequestController {

    @AuraEnabled(cacheable=true)
    public static List<Sample_Out__c> getSampleOutOptions() {
        return [SELECT Id, Name FROM Sample_Out__c];
    }

    @AuraEnabled(cacheable=true)
    public static List<Sample_In__c> getSampleInOptions() {
        return [SELECT Id, Name FROM Sample_In__c];
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getUserOptions() {
        return [SELECT Id, Name FROM User WHERE IsActive = TRUE];
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getSamplesRequestSentToOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Sample_Request__c.Samples_Request_Sent_to__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry entry : picklistValues) {
            Map<String, String> picklistOption = new Map<String, String>();
            picklistOption.put('label', entry.getLabel());
            picklistOption.put('value', entry.getValue());
            options.add(picklistOption);
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductOptions() {
        return [SELECT Id, Name FROM Product2];
    }

    @AuraEnabled
    public static Id createSampleRequest(
        Id recordId, // Opportunity Id to relate the request to
        String sampleOutSentTo,
        Date requestDate,
        Date receivedDate,
        Id personId,
        Id accountId,
        Id countryId,
        Id UnitId,
        string packet,
        Decimal delayDays,
        String sampleout,
        String samplein,
        String ciNo,
        String ci,
        String srefno,
         String unitOfMeasure ,
        List<Map<String, Object>> products
    ) {
        // Ensure the Opportunity ID is valid
        if (recordId == null) {
            throw new AuraHandledException('Opportunity ID cannot be null');
        }

        // Step 1: Create Sample Request Record related to Opportunity
        Sample_Request__c newRequest = new Sample_Request__c(
            Enquiry__c = recordId, // Link the sample request to Opportunity using Enquiry__c
            Samples_Request_Sent_to__c = sampleOutSentTo,
            Request_Date__c = requestDate,
            Received_Date__c = receivedDate,
            Person__c = personId,
            Company_Name__c = accountId,
            Country__c = countryId
           // Account__c = AccountId
        );
        insert newRequest;
        System.debug('AccountId: ' + AccountId);
System.debug('CountryId: ' + countryId);
                System.debug('Company_Name__c: ' + AccountId);


        // Debugging to ensure the Sample Request was created
        System.debug('Sample Request Created: ' + newRequest);

        // Step 2: Handle Sample Out Records (if sampleOutSentTo provided)
        if(sampleout== 'SampleOut'){
   //     if (sampleOutSentTo != null && !String.isEmpty(sampleOutSentTo)) {
           List<Sample_Out__c> sampleOutRecords = new List<Sample_Out__c>();
for (Map<String, Object> product : products) {
    Decimal quantityValue = 0;
    if (product.get('quantity') != null) {
        try {
            quantityValue = Decimal.valueOf(String.valueOf(product.get('quantity')));
        } catch (Exception e) {
            quantityValue = 0;
        }
    }

    Sample_Out__c sampleOutRecord = new Sample_Out__c(
        Sample_Request__c = newRequest.Id,
        Product_Name__c = (Id) product.get('prodId'),
        Quantity__c = quantityValue,
        Packets__c = (String) product.get('packet'),
        Quality__c = (String) product.get('quality'),
        Colour_Index_Name__c = (String) product.get('ciNo'),
        Application__c = (String) product.get('application'),
        Unit_of_Measure__c = (String) product.get('unitOfMeasure'),
        Sample_Sent_to_Unit__c = (Id) product.get('unitId')
    );
    sampleOutRecords.add(sampleOutRecord);
}

insert sampleOutRecords;

   //     }
        }
        // Step 3: Handle Sample In Records (if products provided for Sample In)
        if(samplein== 'SampleIn'){
        if (products != null && products.size() > 0) {
            List<Sample_In__c> sampleInRecords = new List<Sample_In__c>();
            for (Map<String, Object> product : products) {
                // Convert 'annualQtyOfBusiness' from String to Decimal
              Decimal annualQty = null;
        if (product.containsKey('annualQtyOfBusiness') && product.get('annualQtyOfBusiness') != null) {
            try {
                annualQty = Decimal.valueOf(String.valueOf(product.get('annualQtyOfBusiness')));
            } catch (Exception e) {
                System.debug('Error parsing annualQtyOfBusiness: ' + e.getMessage());
            }
        }

        // Safely get prodId
        Id prodId = null;
        if (product.containsKey('prodId') && product.get('prodId') != null) {
            prodId = (Id) product.get('prodId');
        }

                Sample_In__c newSampleIn = new Sample_In__c(
                    Sample_Request__c = newRequest.Id,
                    Customer_s_Product_Name__c = (String) product.get('productName'),
                    Application__c = (String) product.get('application'),
                    C_I__c = (String) product.get('ci'),
                    S_In_Ref_No__c = (String) product.get('srefno'),
                    VOL_Product_Name__c = (Id) product.get('prodId'),
                    Annual_Qty_of_Business__c = annualQty,
                    Courier_Tracking_No_Date__c = (String) product.get('courierno'),
                     Sample_Sent_to_Unit__c = (Id) product.get('unitId')
                );
                sampleInRecords.add(newSampleIn);
            }
            insert sampleInRecords; // Insert all Sample In records
        }
        }

        // Return the ID of the newly created Sample Request
        return newRequest.Id;
    }

    @AuraEnabled(cacheable=true)
    public static String getOppaccById(Id opportunityId) {
        // Fetch Opportunity along with related Account and Country fields
        opportunity opp = [SELECT Id, Name, AccountId, Account.Country__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            return opp.AccountId;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getOppcountryById(Id opportunityId) {
        // Fetch Opportunity along with related Account and Country fields
        opportunity opp = [SELECT Id, Name, AccountId,Country__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            return opp.Country__c;
    }
    
      public class pinWrap1{
        public string Id;
        public string countryId;
        public string accountId;
        
    }
    
     @AuraEnabled(cacheable=true)
    public static string getopptails(String opportunityId) {
        try {
            opportunity pinCodeRecord = [SELECT Id, AccountId,Country__c
                                     FROM opportunity WHERE id = :opportunityId LIMIT 1];
            pinWrap1 pin = new pinWrap1();
            
            pin.countryId = pinCodeRecord.Country__c;
            pin.accountId = pinCodeRecord.AccountId;
            
            
            
            return JSON.serialize(pin); 
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Pin Code details: ' + e.getMessage());
        }
    }	
    
    @AuraEnabled(cacheable=true)
public static Map<String, String> getOpportunityAccountAndCountry(Id opportunityId) {
    Map<String, String> result = new Map<String, String>();
    
    Opportunity opp = [SELECT AccountId, Account.Name, Account.Country__r.Name FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
    
    result.put('accountId', opp.AccountId);
    result.put('accountName', opp.Account.Name);
    result.put('countryId', opp.Account.Country__c);
    result.put('countryName', opp.Account.Country__r.Name);
    
    return result;
}
 @AuraEnabled(cacheable=true)
    public static Map<String, String> getCurrentUserName() {
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Id, Name,User_Division__c  FROM User WHERE Id = :currentUserId LIMIT 1];
        
        Map<String, String> userInfo = new Map<String, String>();
        userInfo.put('Id', currentUser.Id); // User Id
        userInfo.put('Name', currentUser.Name); // User Name
        
        return userInfo; 
    }
    
    @AuraEnabled(cacheable = true)
public static List<Map<String, String>> getUnitOfMeasureOptions() {
    List<Map<String, String>> options = new List<Map<String, String>>();

    // Describe the field to get the picklist values for Sample_Out__c's Unit_of_Measure__c
    Schema.DescribeFieldResult fieldResult = Sample_Out__c.Unit_of_Measure__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

    // Loop through picklist values and store them in a Map
    for (Schema.PicklistEntry entry : picklistValues) {
        Map<String, String> picklistOption = new Map<String, String>();
        picklistOption.put('label', entry.getLabel());
        picklistOption.put('value', entry.getValue());
        options.add(picklistOption);
    }

    return options;
}

}