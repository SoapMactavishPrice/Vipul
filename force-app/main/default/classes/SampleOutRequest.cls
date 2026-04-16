public class SampleOutRequest {

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
    
   @AuraEnabled(cacheable=true)
public static List<Unit_Master__c> getUnitsForSampleWarehouse(String searchKey) {
    System.debug(' getUnitsForSampleWarehouse CALLED with searchKey: ' + searchKey);

    String key = '%' + (searchKey != null ? searchKey : '') + '%';

    List<Unit_Master__c> units = [
        SELECT Id, Name
        FROM Unit_Master__c
        WHERE Sample_Warehouse__c = true
        AND Name LIKE :key
        ORDER BY Name
        LIMIT 20
    ];

    System.debug(' Units fetched count => ' + units.size());
    return units;
}



    @AuraEnabled
    public static Id createSampleOutRequest(
        String opportunityId,
        String sampleOutSentTo,
        Date requestDate,
        Date receivedDate,
        Id personId,
        Id accountId,
        Id enquiryId,
        Id countryId,
        Id UnitId,
        Id prodId,
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
        Sample_Out_Request__c newRequest = new Sample_Out_Request__c(
            Received_Date__c = receivedDate,
            Request_Date__c = requestDate,
            Person__c = personId,
            Company_Name__c = accountId != null ? accountId : null,
            Enquiry_Name__c = enquiryId,
            Country__c = countryId,
            CurrencyIsoCode = accountCurrency
        );
        
        if (String.isNotBlank(opportunityId)) {
            newRequest.Enquiry_Name__c = opportunityId;
        }
        
        try {
            insert newRequest;
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating Sample In Request: ' + e.getMessage());
        }
        
        List<Sample_Out__c> sampleOutRecords = new List<Sample_Out__c>();
        for (Map<String, Object> product : products) {
            Decimal quantityValue = parseDecimal(product.get('quantity'));
            System.debug('DEBUG: unitId value for product: ' + product.get('unitId'));
            
            
            Sample_Out__c sampleOutRecord = new Sample_Out__c(
                Sample_Out_Request__c = newRequest.Id,
                //Product_Name__c = (Id) product.get('prodId'),
                Quantity__c = quantityValue,
                Packets__c = (String) product.get('packet'),
                Quality__c = (String) product.get('quality'),
                Colour_Index_Name__c = (String) product.get('ciNo'),
                Application__c = (String) product.get('application'),
                Unit_of_Measure__c = (String) product.get('unitOfMeasure'),
                Sample_Sent_to_Unit__c = (Id) product.get('unitId')
            );
            
            			
            system.debug('sampleOutRecord.New_Product__c' +sampleOutRecord.New_Product__c);
            
            sampleOutRecord.New_Product__c = Boolean.valueOf(product.get('New_Product__c'));
            
            
            if (sampleOutRecord.New_Product__c) {
                sampleOutRecord.New_Product_Name__c = (String) product.get('New_Product_Name__c');
                sampleOutRecord.New_Product_CI_No__c = (String) product.get('New_Product_CI_No__c');
                
                // Convert the product name to uppercase before saving
                if (sampleOutRecord.New_Product_Name__c != null) {
                    sampleOutRecord.New_Product_Name__c = sampleOutRecord.New_Product_Name__c.toUpperCase();
                }
                sampleOutRecord.Product_Name__c = null;
            } else {
                sampleOutRecord.Product_Name__c = (Id) product.get('prodId');
            }
            
            sampleOutRecords.add(sampleOutRecord);
        }
        
        try {
            insert sampleOutRecords;
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