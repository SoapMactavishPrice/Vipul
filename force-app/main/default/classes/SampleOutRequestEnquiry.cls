public class SampleOutRequestEnquiry {
    
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
    public static List<Product2> getProductOptions() {
        return [SELECT Id, Name FROM Product2];
    }
    
    @AuraEnabled
    public static Id createSampleOutRequest(
        Id recordId, // Opportunity Id to relate the request to
        String sampleOutSentTo,
        Date requestDate,
        Date receivedDate,
        Id personId,
        Id accountId,
        Id countryId,
        Id UnitId,
        String packet,
        Decimal delayDays,
        String sampleout,
        String samplein,
        String ciNo,
        String ci,
        String srefno,
        String unitOfMeasure,
        String accountCurrency,
        List<Map<String, Object>> products
    ) {
        // Ensure the Opportunity ID is valid
        if (recordId == null) {
            throw new AuraHandledException('Opportunity ID cannot be null');
        }
        
        // Step 1: Create Sample Request Record related to Opportunity
        Sample_Out_Request__c newRequest = new Sample_Out_Request__c(
            Enquiry_Name__c = recordId, // Link the sample request to Opportunity using Enquiry__c
            Request_Date__c = requestDate,
            Received_Date__c = receivedDate,
            Person__c = personId,
            Company_Name__c = accountId,
            Country__c = countryId,
            CurrencyIsoCode = accountCurrency
        );
        insert newRequest;
        
        // Debugging to ensure the Sample Request was created
        System.debug('Sample Request Created: ' + newRequest);
        
        List<Sample_Out__c> sampleOutRecords = new List<Sample_Out__c>();
        for (Map<String, Object> product : products) {
            Decimal quantityValue = parseDecimal(product.get('quantity'));
            
            Sample_Out__c sampleOutRecord = new Sample_Out__c(
                Sample_Out_Request__c = newRequest.Id,
                Quantity__c = quantityValue,
                Packets__c = (String) product.get('packet'),
                Quality__c = (String) product.get('quality'),
                Colour_Index_Name__c = (String) product.get('ciNo'),
                Application__c = (String) product.get('application'),
                Unit_of_Measure__c = (String) product.get('unitOfMeasure'),
                Sample_Sent_to_Unit__c = (Id) product.get('unitId')
            );
            
            sampleOutRecord.New_Product__c = Boolean.valueOf(product.get('New_Product__c'));
            
            if (sampleOutRecord.New_Product__c) {
                sampleOutRecord.New_Product_Name__c = ((String) product.get('New_Product_Name__c')).toUpperCase();
                sampleOutRecord.New_Product_CI_No__c = (String) product.get('New_Product_CI_No__c');
                sampleOutRecord.Product_Name__c = null;
            } else {
                sampleOutRecord.Product_Name__c = (Id) product.get('prodId');
            }
            
            sampleOutRecords.add(sampleOutRecord);
        }
        
        try {
            insert sampleOutRecords; // Insert all Sample Out records
            System.debug('Sample Out Records Created: ' + sampleOutRecords);
        } catch (DmlException e) {
            System.debug('Error inserting Sample Out records: ' + e.getMessage());
            throw new AuraHandledException('Error inserting Sample Out records: ' + e.getMessage());
        }
        
        // Return the ID of the newly created Sample Request
        return newRequest.Id;
    }
    
    private static Decimal parseDecimal(Object value) {
        try {
            return value != null ? Decimal.valueOf(String.valueOf(value)) : null;
        } catch (Exception e) {
            System.debug('Error parsing decimal value: ' + e.getMessage());
            return null;
        }
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
        result.put('enquiryId', opp.Id);
        
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
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getAccountAndCountryDetails(Id accountId) {
        Map<String, String> result = new Map<String, String>();
        Account acc = [SELECT Id, Name, Country__c, Country__r.Name FROM Account WHERE Id = :accountId LIMIT 1];

        result.put('accountId', acc.Id);
        result.put('accountName', acc.Name);
        result.put('countryId', acc.Country__c);
        result.put('countryName', acc.Country__r.Name);

        return result;
    }
    
}