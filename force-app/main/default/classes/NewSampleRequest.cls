public with sharing class NewSampleRequest {

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
        String opportunityId, // Now optional parameter
        String sampleOutSentTo,
        Date requestDate,
        Date receivedDate,
        Id personId,
        Id accountId,
        Id enquiryId,
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
        List<Map<String, Object>> products
    ) {
        // Create Sample Request Record - Opportunity link is now optional
        Sample_Request__c newRequest = new Sample_Request__c(
            Samples_Request_Sent_to__c = sampleOutSentTo,
            Request_Date__c = requestDate,
            Received_Date__c = receivedDate,
            Person__c = personId,
         //   Company_Name__c = accountId,
                    Company_Name__c = accountId != null ? accountId : null,

            Enquiry__c = enquiryId,
            Country__c = countryId
        );
        
        // Only link to Opportunity if ID was provided
        if (String.isNotBlank(opportunityId)) {
            newRequest.Enquiry__c = opportunityId;
        }
        
        insert newRequest;

        // Handle Sample Out Records if needed
        if(sampleout == 'SampleOut') {
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

                    System.debug('DEBUG: unitId value for product: ' + product.get('unitId'));

                
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
            
        }

        
        
        // Handle Sample In Records if needed
     if (samplein == 'SampleIn' && products != null && products.size() > 0) {
    List<Sample_In__c> sampleInRecords = new List<Sample_In__c>();
    
    for (Map<String, Object> product : products) {
        // Safely parse annualQtyOfBusiness
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
            VOL_Product_Name__c = prodId,
            Annual_Qty_of_Business__c = annualQty,
            Courier_Tracking_No_Date__c = (String) product.get('courierno'),
            Sample_Sent_to_Unit__c = (Id) product.get('unitId')
        );

        sampleInRecords.add(newSampleIn);
    }

    insert sampleInRecords;
}

        return newRequest.Id;
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> searchOpportunities(String searchTerm) {
        String query = 'SELECT Id, Name, Account.Name, Account.Country__r.Name FROM Opportunity';
        if (String.isNotBlank(searchTerm)) {
            query += ' WHERE Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'';
            query += ' OR Account.Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'';
        }
        query += ' ORDER BY CreatedDate DESC LIMIT 20';
        return Database.query(query);
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

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCurrentUserName() {
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Id, Name, User_Division__c FROM User WHERE Id = :currentUserId LIMIT 1];
        
        Map<String, String> userInfo = new Map<String, String>();
        userInfo.put('Id', currentUser.Id);
        userInfo.put('Name', currentUser.Name);
        
        return userInfo; 
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getUnitOfMeasureOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Sample_Out__c.Unit_of_Measure__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistValues) {
            Map<String, String> picklistOption = new Map<String, String>();
            picklistOption.put('label', entry.getLabel());
            picklistOption.put('value', entry.getValue());
            options.add(picklistOption);
        }
        return options;
    }
}