public with sharing class SampleInRequest {

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
        Schema.DescribeFieldResult fieldResult = Sample_In__c.Unit_of_Measure__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistValues) {
            Map<String, String> picklistOption = new Map<String, String>();
            picklistOption.put('label', entry.getLabel());
            picklistOption.put('value', entry.getValue());
            options.add(picklistOption);
        }
        return options;
    }

    @AuraEnabled
    public static Id createSampleInRequest(
        String opportunityId,
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
        String comment,
        String custRef,
        List<Map<String, Object>> products
    ) {
        Sample_In_Request__c newRequest = new Sample_In_Request__c(
            Received_Date__c = receivedDate,
            Person__c = personId,
            Company_Name__c = accountId != null ? accountId : null,
            Enquiry_Name__c = enquiryId,
            Country__c = countryId
        );

        if (String.isNotBlank(opportunityId)) {
            newRequest.Enquiry_Name__c = opportunityId;
        }

        try {
            insert newRequest;
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating Sample In Request: ' + e.getMessage());
        }

            List<Sample_In__c> sampleInRecords = new List<Sample_In__c>();

            for (Map<String, Object> product : products) {
                Decimal annualQty = parseDecimal(product.get('annualQtyOfBusiness'));
                Decimal quantityValue = parseDecimal(product.get('quantity'));
                Id prodId = (Id) product.get('prodId');

                Sample_In__c newSampleIn = new Sample_In__c(
                    Sample_In_Request__c = newRequest.Id,
                    Customer_s_Product_Name__c = (String) product.get('productName'),
                    Application__c = (String) product.get('application'),
                    C_I__c = (String) product.get('ci'),
                    S_In_Ref_No__c = (String) product.get('srefno'),
                    VOL_Product_Name__c = prodId,
                    Annual_Qty_of_Business__c = annualQty,
                    Courier_Tracking_No_Date__c = (String) product.get('courierno'),
                    Sample_Sent_to_Unit__c = (Id) product.get('unitId'),
                    Quantity__c = quantityValue,
                    Unit_of_Measure__c = (String) product.get('unitOfMeasure'),
                    Comments__c = (String) product.get('comment'),
                    Customer_Reference_No__c = (String) product.get('custRef'),
                    Marketing_Person__c = personId
                );

                sampleInRecords.add(newSampleIn);
            }

            try {
                insert sampleInRecords;
            } catch (DmlException e) {
                throw new AuraHandledException('Error creating Sample In records: ' + e.getMessage());
            }

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
}