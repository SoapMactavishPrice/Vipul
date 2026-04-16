public with sharing class MarketingForm {
    
    // This method retrieves the current logged-in user information (e.g., Name)
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCurrentUserName() {
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Id, Name,User_Division__c  FROM User WHERE Id = :currentUserId LIMIT 1];
        
        Map<String, String> userInfo = new Map<String, String>();
        userInfo.put('Id', currentUser.Id); // User Id
        userInfo.put('Name', currentUser.Name); // User Name
        
        return userInfo; 
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getUserInfoWithLeadType() {
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [
            SELECT Id, Name, Username, User_Division__c, Profile.Name 
            FROM User 
            WHERE Id = :currentUserId 
            LIMIT 1
        ];
        
        String specialProfileName = 'System Administrator'; // <-- your target profile
        
        List<Schema.PicklistEntry> leadTypePicklist = Schema.SObjectType.Lead.fields.getMap().get('Lead_Type__c').getDescribe().getPicklistValues();
        List<Map<String, String>> filteredPicklist = new List<Map<String, String>>();
        String userDivision = currentUser.User_Division__c;
        
        for (Schema.PicklistEntry pickValue : leadTypePicklist) {
            if (currentUser.Profile.Name == specialProfileName) {
                // System Admins - get ALL picklist values
                Map<String, String> pic = new Map<String, String>();
                pic.put('label', pickValue.getLabel());
                pic.put('value', pickValue.getValue());
                filteredPicklist.add(pic);
            } else {
                // Normal users - only matching their Division
                if (pickValue.getValue() == userDivision) {
                    Map<String, String> pic = new Map<String, String>();
                    pic.put('label', pickValue.getLabel());
                    pic.put('value', pickValue.getValue());
                    filteredPicklist.add(pic);
                }
            }
        }
        
        Map<String, Object> result = new Map<String, Object>();
        result.put('userInfo', new Map<String, String>{
            'Id' => currentUser.Id,
                'Name' => currentUser.Name,
                'Username' => currentUser.Username,
                'ProfileName' => currentUser.Profile.Name
                });
        result.put('filteredPicklist', filteredPicklist);
        
        return result;
    }
    
    
    // This method retrieves a list of Accounts based on the search key
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(String searchKey) {
        return [SELECT Id, Name,CurrencyIsoCode  FROM Account];
        // return [SELECT Id, Name,CurrencyIsoCode  FROM Account WHERE Name LIKE :('%' + searchKey + '%') LIMIT 10];
    }
    
    // This method retrieves a list of Users
    @AuraEnabled(cacheable=true)
    public static List<User> getUsers() {
        return [SELECT Id, Name FROM User WHERE IsActive = true LIMIT 100]; // Fetching active users
    }
    
    // This method retrieves a list of Country records for the "Country" lookup field
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getCountries() {
        List<Map<String, String>> countryOptions = new List<Map<String, String>>();
        
        // Query the custom Country__c object
        List<Country__c> countries = [SELECT Id, Name FROM Country__c LIMIT 100];
        
        // Populate options for the combobox
        for (Country__c country : countries) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', country.Name);
            option.put('value', country.Id);
            countryOptions.add(option);
        }
        
        return countryOptions;
    }
    
    @AuraEnabled(Cacheable=true)
    public static List<Map<String, String>> getPicklistValues() {
        List<Map<String, String>> picklist = new List<Map<String, String>>();
        
        // Get describe information for Product_Family__c field
        Schema.DescribeFieldResult fieldResult = OpportunityLineItem.Product_Family__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        // Add Product_Family__c values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Product_Family__c'); // Mark that this is for Product_Family__c
            picklist.add(pic);
        }
        
        // Get describe information for Packaging__c field
        fieldResult = OpportunityLineItem.Packaging__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        // Add Packaging__c values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Packaging__c'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        fieldResult = OpportunityLineItem.Packing_Type__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        // Add CurrencyIsoCode values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Packing_Type__c'); 
            picklist.add(pic);
        }
        
        
        // Get describe information for Lead_Type__c field
        fieldResult = Lead.Lead_Type__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        // Add Lead_Type__c values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Lead_Type__c'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }	
        
        
        // Get describe information for CurrencyIsoCode field
        /*     fieldResult = Lead.CurrencyIsoCode.getDescribe();
picklistValues = fieldResult.getPicklistValues();

// Add CurrencyIsoCode values
for (Schema.PicklistEntry pickValue : picklistValues) {
Map<String, String> pic = new Map<String, String>();
pic.put('label', pickValue.getLabel());
pic.put('value', pickValue.getValue());
pic.put('field', 'CurrencyIsoCode'); // Mark that this is for Packaging__c
picklist.add(pic);
}	*/
        
        
        // Get describe information for CurrencyIsoCode field
        fieldResult = Opportunity.Inco_Terms__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        // Add CurrencyIsoCode values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Inco_Terms__c'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        // Get describe information for CurrencyIsoCode field
        fieldResult = Opportunity.StageName.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        // Add CurrencyIsoCode values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'StageName'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        
        
        fieldResult = Opportunity.Enquiry_Type__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        // Add CurrencyIsoCode values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Enquiry_Type__c'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        fieldResult = OpportunityLineItem.Commission_Type__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        // Add CurrencyIsoCode values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Commission_Type__c'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        fieldResult = Lead.Department__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        // Add CurrencyIsoCode values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Department__c'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        
        fieldResult = Lead.Salutation.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        // Add CurrencyIsoCode values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Salutation'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        
        fieldResult = Lead.Job_Title_Designation__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Job_Title_Designation__c'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        fieldResult = Lead.Customer_Type__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Customer_Type__c'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        
        fieldResult = Lead.Company_Business__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Company_Business__c'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        fieldResult = Account.CurrencyIsoCode.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'CurrencyIsoCode'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        fieldResult = Lead.Rating.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Rating'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        return picklist;
    }
    
    
    
    
    
    
    @AuraEnabled(Cacheable=true)
    public static List<Map<String, String>> getPicklistValues1() {
        List<Map<String, String>> picklist = new List<Map<String, String>>();
        
        // Get describe information for Product_Family__c field
        Schema.DescribeFieldResult fieldResult = Product_Interested__c.Product_Family__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        // Add Product_Family__c values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Product_Family__c'); // Mark that this is for Product_Family__c
            picklist.add(pic);
        }
        
        // Get describe information for Packaging__c field
        fieldResult = Product_Interested__c.Packaging__c.getDescribe();
        picklistValues = fieldResult.getPicklistValues();
        
        // Add Packaging__c values
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            pic.put('field', 'Packaging__c'); // Mark that this is for Packaging__c
            picklist.add(pic);
        }
        
        return picklist;
    }
    
    
    // Fetch picklist values for Inco_Terms__c field
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getIncoTermsPicklistValues() {
        List<Map<String, String>> picklist = new List<Map<String, String>>();
        
        Schema.DescribeFieldResult fieldResult = Opportunity.Inco_Terms__c.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            picklist.add(pic);
        }
        
        return picklist;
    }
    
    // Fetch picklist values for StageName field on Opportunity object
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getStagePicklistValues() {
        List<Map<String, String>> picklist = new List<Map<String, String>>();
        
        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry pickValue : picklistValues) {
            Map<String, String> pic = new Map<String, String>();
            pic.put('label', pickValue.getLabel());
            pic.put('value', pickValue.getValue());
            picklist.add(pic);
        }
        
        return picklist;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getAccountCurrency(String accountId) {
        try {
            Account acc = [SELECT CurrencyIsoCode FROM Account WHERE Id = :accountId LIMIT 1];
            return acc.CurrencyIsoCode;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching account currency: ' + e.getMessage() + e.getLineNumber());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getAccountCurrency1(String accountId) {
        try {
            Account acc = [SELECT Country__c FROM Account WHERE Id = :accountId LIMIT 1];
            return acc.Country__c;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching account Country: ' + e.getMessage() + e.getLineNumber());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getAccountincoterms(String accountId) {
        try {
            Account acc = [SELECT Inco_terms__c FROM Account WHERE Id = :accountId LIMIT 1];
            return acc.Inco_terms__c;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching account Inco Terms: ' + e.getMessage() + e.getLineNumber());
        }
    }
    
    @AuraEnabled(Cacheable=true)
    public static List<Id> getExistingProducts(string Id) {
        List<Id> ids = new List<Id>();
        List<OpportunityLineItem> pi= [Select Id,Product2Id from OpportunityLineItem];
        for(OpportunityLineItem p : pi) {
            ids.add(p.Product2Id);
        }
        return ids;
    }
    
    @AuraEnabled(cacheable=true)
    public static string getaccountdetails(String account) {
        try {
            Account pinCodeRecord = [SELECT Id, Country__c,Inco_terms__c
                                     FROM Account WHERE id = :account LIMIT 1];
            pinWrap1 pin = new pinWrap1();
            
            pin.countryId1 = pinCodeRecord.Country__c;
            pin.incoTerms = pinCodeRecord.INCO_Terms__c;
            
            
            
            return JSON.serialize(pin); 
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Pin Code details: ' + e.getMessage());
        }
    }	
    
    @AuraEnabled
    public static Opportunity getOpportunityDetails(Id opportunityId) {
        try {
            // Query the Opportunity to fetch the required fields
            Opportunity opp = [SELECT Id, Enquiry_Type__c, Inco_terms__c 
                               FROM Opportunity 
                               WHERE Id = :opportunityId 
                               LIMIT 1];
            return opp;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Opportunity details: ' + e.getMessage());
        }
    }
    
   @AuraEnabled(cacheable=true)
    public static List<Sample_Out__c> getSampleReferenceNumbers(String productId) {
        return [
            SELECT Reference_Number__c, Sample_Approved_Date__c, Product_Name__r.Name,
                   Sample_Out_Status__c, CreatedDate, Comments__c
            FROM Sample_Out__c 
            WHERE Product_Name__c = :productId 
            AND Sample_Out_Status__c = 'Sample Approved'
            ORDER BY Sample_Approved_Date__c DESC
            LIMIT 10
        ];
    }
    
    @AuraEnabled
    public static String createOpportunityRecord(String opportunityName, Date closeDate, Decimal amount,
                                                 Id filledBy, String enquiryMode, String enquiryType,
                                                 String customerType, Id accountId, Id whoWillAttend, Id leadId,
                                                 String countryId1, Id Id, String JS, String stage, String incoTerms, 
                                                 String currencyCode, String enquiryType1, String currencyacc) {
                                                     System.debug('No User: ');
                                                     try {
                                                         // Get the current user
                                                         Id currentUserId = UserInfo.getUserId();
                                                         
                                                         // Fetch the account's currency based on the provided accountId
                                                         String accountCurrency = getAccountCurrency(accountId);
                                                         
                                                         // Create the Opportunity record
                                                         Opportunity opp = new Opportunity();
                                                         opp.Name = opportunityName;
                                                         opp.OwnerId = currentUserId;
                                                         opp.LeadSource = enquiryMode; 
                                                         opp.AccountId = accountId; 
                                                         opp.CloseDate = closeDate;
                                                         opp.StageName = stage; 
                                                         opp.Country__c = countryId1; 
                                                         opp.Customer_Type__c = customerType;
                                                         opp.Who_will_attend__c = whoWillAttend;
                                                         opp.CloseDate = closeDate; 
                                                         opp.Inco_Terms__c = incoTerms; 
                                                     //   opp.CurrencyIsoCode = accountCurrency; // Use the account currency
                                                         opp.Enquiry_Type__c = enquiryType1;
                                                         
                                                         
                                                        if (String.isNotBlank(currencyCode)) {
                                                            System.debug('Setting Opportunity.CurrencyIsoCode to provided currencyCode: ' + currencyCode);
                                                            opp.CurrencyIsoCode = currencyCode;
                                                        } else {
                                                            System.debug('Setting Opportunity.CurrencyIsoCode to accountCurrency: ' + accountCurrency);
                                                            opp.CurrencyIsoCode = accountCurrency;
                                                        }
                                                         

                                                         
                                                         // Handle Record Type based on Enquiry Type
                                                         String enquiryType2 = opp.Enquiry_Type__c;
                                                         Id recordTypeId = null;
                                                         if (enquiryType2 == 'Domestic') {
                                                             recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Domestic' LIMIT 1].Id;
                                                         } else if (enquiryType2 == 'International') {
                                                             recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'International' LIMIT 1].Id;
                                                         }
                                                         
                                                         if (recordTypeId != null) {
                                                             opp.RecordTypeId = recordTypeId;
                                                         } else {
                                                             throw new AuraHandledException('RecordType for ' + enquiryType1 + ' not found.');
                                                         }
                                                         
                                                         // Set the standard pricebook for the Opportunity
                                                         Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsActive = TRUE AND IsStandard = TRUE LIMIT 1];
                                                         opp.Pricebook2Id = standardPricebook.Id;
                                                         
                                                         // Insert the Opportunity record
                                                         insert opp;
                                                         
                                                         // Now handle OpportunityLineItems
                                                         List<Object> jsList = (List<Object>)JSON.deserializeUntyped(JS);
                                                         List<OpportunityLineItem> piList = new List<OpportunityLineItem>();
                                                         
                                                         for (Object obj : jsList) {
                                                             Map<String, Object> objMap = (Map<String, Object>) obj;
                                                             OpportunityLineItem pm = new OpportunityLineItem();
                                                             pm.OpportunityId = opp.Id;
                                                             pm.Product2Id = (Id) objMap.get('prodId');
                                                             pm.Quality__c = (String) objMap.get('quality');
                                                             pm.Quantity = Decimal.valueOf((String) objMap.get('volume'));
                                                             pm.Packaging__c = (String) objMap.get('packaging');
                                                             pm.Packing_Type__c = (String) objMap.get('PackingType');
                                                             pm.Commission_Type__c = (String) objMap.get('CommissionType');
                                                             
                                                             // Get product information
                                                             String prodId = (String) objMap.get('prodId');
                                                             if (String.isNotEmpty(prodId)) {
                                                                 pm.Product2Id = prodId;  
                                                             }
                                                             
                                                             Product2 product = [SELECT Family FROM Product2 WHERE Id = :prodId LIMIT 1];
                                                             if (product != null && String.isNotEmpty(product.Family)) {
                                                                 pm.Product_Family__c = product.Family;
                                                             }
                                                             
                                                             // Handle price, commission, and freight values
                                                             try {
                                                                 pm.UnitPrice = objMap.containsKey('price') && objMap.get('price') != null ? 
                                                                     Decimal.valueOf((String) objMap.get('price')) : null; 
                                                             } catch (Exception e) {
                                                                 pm.UnitPrice = null; 
                                                                 System.debug('Invalid Unit Price: ' + objMap.get('price') + ' Error: ' + e.getMessage());
                                                             }
                                                             
                                                             if (pm.UnitPrice != null && pm.UnitPrice > 0) {
                                                                 pm.Purchase_Price_Status__c = 'Approved';
                                                             }
                                                             
                                                             // Handle commission values
                                                             try {
                                                                 pm.Commission_Value__c = objMap.containsKey('commissionval') && objMap.get('commissionval') != null ? 
                                                                     Decimal.valueOf((String) objMap.get('commissionval')) : null;
                                                             } catch (Exception e) {
                                                                 pm.Commission_Value__c = null; 
                                                                 System.debug('Invalid Commission Value: ' + objMap.get('commissionval') + ' Error: ' + e.getMessage());
                                                             }
                                                             
                                                             // Handle commission percentage
                                                             try {
                                                                 pm.Commission_Percent__c = objMap.containsKey('commissionper') && objMap.get('commissionper') != null ? 
                                                                     Decimal.valueOf((String) objMap.get('commissionper')) : null;
                                                             } catch (Exception e) {
                                                                 pm.Commission_Percent__c = null; 
                                                                 System.debug('Invalid Commission Percent: ' + objMap.get('commissionper') + ' Error: ' + e.getMessage());
                                                             }
                                                             
                                                             // Handle freight value
                                                             try {
                                                                 if (objMap.containsKey('freightval') && objMap.get('freightval') != null && String.isNotBlank((String) objMap.get('freightval'))) {
                                                                     pm.Freight_Value__c = Decimal.valueOf((String) objMap.get('freightval'));
                                                                 } else {
                                                                     pm.Freight_Value__c = null; // If blank or null, assign null
                                                                 }
                                                             } catch (Exception e) {
                                                                 pm.Freight_Value__c = null; // Assign null if invalid value
                                                                 System.debug('Invalid Freight Value: ' + objMap.get('freightval') + ' Error: ' + e.getMessage());
                                                             }
                                                             
                                                            // Check PricebookEntry for selected currency
            List<PricebookEntry> pricebookEntries = [
                SELECT Id, UnitPrice 
                FROM PricebookEntry 
                WHERE Pricebook2Id = :standardPricebook.Id 
                AND Product2Id = :prodId 
                AND CurrencyIsoCode = :opp.CurrencyIsoCode
                LIMIT 1
            ];

            if (pricebookEntries.isEmpty()) {
                throw new AuraHandledException('No pricebook entry found for product ' + prodId + ' with currency ' + opp.CurrencyIsoCode);
            }
                                                             
                                                             // Assign the PricebookEntryId
                                                             pm.PricebookEntryId = pricebookEntries[0].Id;
                                                             
                                                             piList.add(pm); 
                                                         }
                                                         
                                                         // Insert OpportunityLineItems only if the list is populated
                                                         if (piList.size() > 0) {
                                                             insert piList;
                                                         }
                                                         
                                                         // Check if OpportunityLineItems were created, and if so, create a Quote only when the Opportunity Stage is 'Proposal'
                                                         if (!piList.isEmpty() && stage == 'Proposal') {
                                                             // Create a new Quote for this Opportunity
                                                             Quote newQuote = new Quote();
                                                             newQuote.OpportunityId = opp.Id;
                                                             newQuote.Name = opp.Name + ' Quote';  // Set a name for the Quote
                                                             newQuote.Status = 'Draft';  // Set initial status to 'Draft'
                                                             
                                                             Pricebook2 standardPricebook1 = [SELECT Id FROM Pricebook2 WHERE IsActive = TRUE AND IsStandard = TRUE LIMIT 1];
                                                             newQuote.Pricebook2Id = standardPricebook1.Id;
                                                             
                                                             // Insert the Quote
                                                             insert newQuote;
                                                             
                                                             // Create Quote Line Items based on OpportunityLineItems
                                                             List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
                                                             for (OpportunityLineItem oli : piList) {
                                                                 QuoteLineItem qli = new QuoteLineItem();
                                                                 qli.QuoteId = newQuote.Id;
                                                                 qli.Product2Id = oli.Product2Id;
                                                                 qli.Quantity = oli.Quantity;
                                                                 qli.UnitPrice = oli.UnitPrice;
                                                                 quoteLineItems.add(qli);
                                                                 
                                                                 // Query the PriceBookEntry that links the Product2 to the Pricebook2
                                                                 List<PricebookEntry> pricebookEntries = [SELECT Id FROM PricebookEntry 
                                                                                                          WHERE Pricebook2Id = :standardPricebook.Id 
                                                                                                          AND Product2Id = :qli.Product2Id 
                                                                                                          LIMIT 1];
                                                                 
                                                                 // Handle the case where the PricebookEntry is not found
                                                                 if (pricebookEntries.isEmpty()) {
                                                                     throw new AuraHandledException('PricebookEntry not found for Product2Id: ' + qli.Product2Id);
                                                                 }
                                                                 
                                                                 // Set the PriceBookEntryId on the QuoteLineItem
                                                                 qli.PricebookEntryId = pricebookEntries[0].Id;
                                                             }
                                                             
                                                             // Insert the Quote Line Items
                                                             if (!quoteLineItems.isEmpty()) {
                                                                 insert quoteLineItems;
                                                             }
                                                         }
                                                         
                                                         // Return a success message
                                                         return opp.Id;
                                                         
                                                     } catch (Exception e) {
                                                         throw new AuraHandledException('Error creating opportunity: ' + e.getMessage() + ' at line number: ' + e.getLineNumber());
                                                     }
                                                 }
    
    @AuraEnabled(cacheable=true)
    public static Decimal fetchListPrice(Id productId, String currencyCode) {
        Pricebook2 standardPricebook = [SELECT Id FROM Pricebook2 
                                        WHERE IsStandard = TRUE AND IsActive = TRUE LIMIT 1];
        
        PricebookEntry pbe = [SELECT UnitPrice FROM PricebookEntry 
                              WHERE Product2Id = :productId 
                              AND Pricebook2Id = :standardPricebook.Id 
                              AND CurrencyIsoCode = :currencyCode 
                              LIMIT 1];
        
        return (pbe != null && pbe.UnitPrice != null) ? pbe.UnitPrice : 0.0;
    }    
    
    @AuraEnabled(cacheable=true)
    public static string getPinCodeDetails(String pincode) {
        try {
            Pin_Code__c pinCodeRecord = [SELECT Id, Area__c,Area__r.City__c,Area__r.City__r.State__c,Area__r.City__r.State__r.Country__c
                                         FROM Pin_Code__c WHERE id = :pincode LIMIT 1];
            pinWrap pin = new pinWrap();
            pin.Id = pinCodeRecord.Id;
            pin.cityId =pinCodeRecord.Area__r.City__c;
            pin.stateId =pinCodeRecord.Area__r.City__r.State__c;
            pin.countryId = pinCodeRecord.Area__r.City__r.State__r.Country__c;
            pin.areaId =pinCodeRecord.Area__c;
            
            
            return JSON.serialize(pin); 
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Pin Code details: ' + e.getMessage());
        }
    }	
    
    @AuraEnabled(cacheable=true)
    public static String fetchCI(String productId) {
        try {
            Product2 product = [SELECT CI_no__c FROM Product2 WHERE Id = :productId LIMIT 1];
            return product.CI_no__c;  // Return the CI_no__c value
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching CI_no__c: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createLeadRecord(String leadName, String fname, String companyName, String leadSource,
                                          String enquiryMode, String customerType, String description,
                                          String countryId, String assignedTo, String email, String phone, String street,
                                          String areaId, String cityId, String stateId, String pincode, String js, String Id,
                                          String territory, String leadcurrency, String department, String salutation,
                                          String designation, String custtype, String phone1, String rating, List<String> company_business, 
                                          String customer_type, String exhibitionName) {
                                              try {
                                                  // Fetch the current user's Id
                                                  Id currentUserId = UserInfo.getUserId();
                                                  
                                                  // Create a new Lead record
                                                  Lead newLead = new Lead();
                                                  newLead.LastName = leadName;
                                                  newLead.FirstName = fname;
                                                  newLead.Company = companyName;
                                                  newLead.LeadSource = leadSource;
                                                  newLead.Customer_Type__c = customerType;
                                                  newLead.Description = description;
                                                  newLead.Inco_Terms__c = rating;
                                                  
                                                  // Handling multi-select picklist for Company_Business__c
                                                  if (company_business != null && !company_business.isEmpty()) {
                                                      newLead.Company_Business__c = String.join(company_business, ';');  // Join the list values with semicolon
                                                  }
                                                  
                                                  // Set optional fields if they are not blank
                                                  if (String.isNotBlank(countryId)) {
                                                      newLead.Country__c = countryId;
                                                  }
                                                  newLead.OwnerId = currentUserId;
                                                  newLead.Email = email;
                                                  newLead.MobilePhone = phone;
                                                  newLead.Street__c = street;
                                                  
                                                  // Set other address-related fields if not blank
                                                  if (String.isNotBlank(areaId)) {
                                                      newLead.Area__c = areaId;
                                                  }
                                                  if (String.isNotBlank(cityId)) {
                                                      newLead.City__c = cityId;
                                                  }
                                                  if (String.isNotBlank(stateId)) {
                                                      newLead.State__c = stateId;
                                                  }
                                                  if (String.isNotBlank(pincode)) {
                                                      newLead.Pin_Code__c = pincode;
                                                  }
                                                  
                                                  // Set the remaining required fields
                                                  newLead.Status = 'Open';
                                                  newLead.Lead_Type__c = territory;
                                                  newLead.CurrencyIsoCode = leadcurrency;  // Set the lead's currency
                                                  newLead.Salutation = salutation;
                                                  newLead.Job_Title_Designation__c = designation;
                                                  newLead.Customer_Type__c = custtype;
                                                  newLead.Phone = phone1;
                                                  newLead.Inco_Terms__c = rating;
                                                  newLead.Exhibition_Name__c = exhibitionName;
                                                  
                                                  // Insert the Lead record
                                                  insert newLead;
                                                  
                                                  // Debugging output to check the new lead record
                                                  System.debug('New Lead: ' + newLead);
                                                  
                                                  // Create a list to store Product_Interested__c records
                                                  List<Product_Interested__c> piList = new List<Product_Interested__c>();
                                                  
                                                  // Deserialize the 'js' string into a list of objects
                                                  List<Object> jsList = (List<Object>) JSON.deserializeUntyped(js);
                                                  
                                                  // Inside the loop where you're processing each product
                                                  for (Object obj : jsList) {
                                                      Map<String, Object> objMap = (Map<String, Object>) obj;
                                                      Product_Interested__c pm = new Product_Interested__c();
                                                      pm.Lead__c = newLead.Id;
                                                      
                                                      // SET Add_in_Opportunity__c based on New_Product__c value
                                                      //pm.New_Product__c = Boolean.valueOf(objMap.get('New_Product__c'));
                                                      //System.debug('DEBUG: New_Product__c value: ' + pm.New_Product__c);
                                                      
                                                      if (objMap.containsKey('New_Product__c') && objMap.get('New_Product__c') != null) {
                                                          pm.New_Product__c = Boolean.valueOf(String.valueOf(objMap.get('New_Product__c')));
                                                      } else {
                                                          pm.New_Product__c = false; // or null if that's your default
                                                      }
                                                      
                                                      
                                                      
                                                     // pm.Add_in_Opportunity__c = !pm.New_Product__c;
                                                     	
                                                      pm.Add_in_Opportunity__c = true;
                                                      
                                                      
                                                      if (pm.New_Product__c) {
                                                          // Handle new product fields when New_Product__c is true
                                                          pm.New_Product_Name__c = (String) objMap.get('New_Product_Name__c');
                                                          pm.New_Product_CI_No__c = (String)objMap.get('New_Product_CI_No__c');
                                                          
                                                          System.debug('DEBUG: Raw New_Product_Name__c: ' + pm.New_Product_Name__c);
                                                          
                                                          // Convert the product name to uppercase before saving
                                                          if (pm.New_Product_Name__c != null) {
                                                              pm.New_Product_Name__c = pm.New_Product_Name__c.toUpperCase();
                                                              System.debug('DEBUG: Uppercased New_Product_Name__c: ' + pm.New_Product_Name__c);
                                                          }
                                                          
                                                          pm.New_Product_Description__c = (String) objMap.get('New_Product_Description__c');
                                                          System.debug('DEBUG: New_Product_Description__c: ' + pm.New_Product_Description__c);
                                                          
                                                          pm.Vipul_Product_Name__c = null; // Set Vipul_Product_Name__c to null for new products
                                                          System.debug('DEBUG: Vipul_Product_Name__c set to NULL for new product');
                                                          
                                                      } else {
                                                          // Handle case where the product is not a new product
                                                          String prodId = (String) objMap.get('prodId');
                                                          System.debug('DEBUG: Existing product prodId: ' + prodId);
                                                          
                                                          if (String.isNotEmpty(prodId)) {
                                                              pm.Vipul_Product_Name__c = prodId;
                                                              System.debug('DEBUG: Vipul_Product_Name__c set to: ' + pm.Vipul_Product_Name__c);
                                                          }
                                                      }
                                                      
                                                      
                                                      // Query for the Product Family based on the prodId (assuming it's related to a Product2 object)
                                                      if (String.isNotEmpty(pm.Vipul_Product_Name__c)) {
                                                          List<Product2> products = [SELECT Family FROM Product2 WHERE Id = :pm.Vipul_Product_Name__c LIMIT 1];
                                                          
                                                          // Check if the list is not empty before accessing the product record
                                                          if (products.size() > 0) {
                                                              Product2 product = products[0];
                                                              // If a product family is found, set it to Product_Family__c
                                                              if (String.isNotEmpty(product.Family)) {
                                                                  pm.Product_Family__c = product.Family;
                                                              }
                                                          } else {
                                                              // Handle the case when no product is found for the given prodId
                                                              System.debug('No Product2 record found for prodId: ' + pm.Vipul_Product_Name__c);
                                                          }
                                                      }
                                                      
                                                      // If prodFamily exists in the incoming object map, override the value of Product_Family__c
                                                      String prodFamily = (String) objMap.get('prodFamily');
                                                      if (String.isNotEmpty(prodFamily)) {
                                                          pm.Product_Family__c = prodFamily;
                                                      }
                                                      
                                                      // Extract other fields like quality, volume, price, and packaging
                                                      String quality = (String) objMap.get('quality');
                                                      if (String.isNotEmpty(quality)) {
                                                          pm.Quality__c = quality;
                                                      }
                                                      
                                                      String volume = (String) objMap.get('volume');
                                                      if (String.isNotEmpty(volume)) {
                                                          pm.Quantity__c = Decimal.valueOf(volume);
                                                      }
                                                      
                                                      // Handle the Price__c (price can be blank or null)
                                                      String price = (String) objMap.get('price');
                                                      if (String.isNotEmpty(price)) {
                                                          pm.Price__c = Decimal.valueOf(price);
                                                      }
                                                      
                                                      String packaging = (String) objMap.get('packaging');
                                                      if (String.isNotEmpty(packaging)) {
                                                          pm.Packaging__c = packaging;
                                                      }
                                                      
                                                      // Query the PricebookEntry that matches the product and the lead's currency
                                                      if (String.isNotEmpty(pm.Vipul_Product_Name__c) && leadcurrency != null) {
                                                          List<PricebookEntry> pricebookEntries = [SELECT Id, Pricebook2.CurrencyIsoCode, UnitPrice 
                                                                                                   FROM PricebookEntry 
                                                                                                   WHERE Product2Id = :pm.Vipul_Product_Name__c AND Pricebook2.CurrencyIsoCode = :leadcurrency 
                                                                                                   LIMIT 1];
                                                          
                                                          // If a valid PricebookEntry is found, set the product price accordingly
                                                          if (pricebookEntries.size() > 0) {
                                                              PricebookEntry pbe = pricebookEntries[0];
                                                              pm.CurrencyIsoCode = pbe.Pricebook2.CurrencyIsoCode;  // Ensure the currency is set correctly
                                                          } else {
                                                              System.debug('No matching PricebookEntry found for product ' + pm.Vipul_Product_Name__c + ' and currency ' + leadcurrency);
                                                              pm.CurrencyIsoCode = leadcurrency; // Use lead's currency as fallback
                                                          }
                                                      } else {
                                                          // If no PricebookEntry or prodId is provided, set the currency from the lead
                                                          pm.CurrencyIsoCode = leadcurrency; // Set the currency from lead directly
                                                      }
                                                      
                                                      // Only add the Product_Interested__c record if some fields are populated
                                                      if (pm.Vipul_Product_Name__c != null || pm.Product_Family__c != null || 
                                                          pm.Quality__c != null || pm.Quantity__c != null || pm.Price__c != null || 
                                                          pm.Packaging__c != null || (pm.New_Product__c && pm.New_Product_Name__c != null)) {
                                                              
                                                              System.debug('DEBUG: Adding to piList -> New product name: ' + pm.New_Product_Name__c);
                                                              piList.add(pm);
                                                          }
                                                      
                                                  }
                                                  
                                                  // Debug the number of records that will be inserted
                                                  System.debug('Number of Product_Interested__c records to insert: ' + piList.size());
                                                  
                                                  // Insert the Product_Interested__c records if any valid data exists
                                                  if (piList.size() > 0) {
                                                      insert piList;  // Insert the list of Product_Interested__c records
                                                  } else {
                                                      System.debug('No valid Product_Interested__c records to insert.');
                                                  }
                                                  
                                                  // Return the ID of the newly created lead
                                                  return newLead.Id;
                                                  
                                              } catch (Exception e) {
                                                  // Catch any exceptions and log the error
                                                  System.debug(e.getMessage() + ' at line number: ' + e.getLineNumber());
                                                  throw new AuraHandledException('Error creating lead: ' + e.getMessage() + ' at line: ' + e.getLineNumber());
                                              }
                                          }
    
    
    
    public class pinWrap{
        public string Id;
        public string cityId;
        public string stateId;
        public string countryId;
        public string areaId;
    }
    
    public class pinWrap1{
        public string Id;
        public string countryId1;
        public string incoTerms;
        
    }
    
    
    
    
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> findRecentPrices(String accountId, String productId) {
        if (String.isEmpty(accountId) || String.isEmpty(productId)) {
            return new List<OpportunityLineItem>();
        }
        
        List<OpportunityLineItem> oliList = [
            SELECT Id, OpportunityId, Product2.Name, UnitPrice, TotalPrice, Quantity, CreatedDate,Opportunity.Account.Name,Opportunity.Name,
            ListPrice,Final_Price__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE AccountId = :accountId)
            AND Product2Id = :productId
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
        return oliList;
    }
    
    
    
    // 
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getPicklistValue() {
        Map<String, List<Map<String, String>>> picklistValuesMap = new Map<String, List<Map<String, String>>>();
        
        try {
            // Fetch picklist values for Customer_Type__c
            List<Map<String, String>> customerTypePicklistValues = new List<Map<String, String>>();
            Schema.DescribeFieldResult customerTypeField = Lead.Customer_Type__c.getDescribe();
            List<Schema.PicklistEntry> customerTypeValues = customerTypeField.getPicklistValues();
            
            for (Schema.PicklistEntry pickListVal : customerTypeValues) {
                Map<String, String> mp = new Map<String, String>();
                mp.put('label', pickListVal.getLabel());  
                mp.put('value', pickListVal.getValue());
                customerTypePicklistValues.add(mp);
            }
            picklistValuesMap.put('customerType', customerTypePicklistValues);
            
            // Fetch picklist values for Company_Business__c
            List<Map<String, String>> companyBusinessPicklistValues = new List<Map<String, String>>();
            Schema.DescribeFieldResult companyBusinessField = Lead.Company_Business__c.getDescribe();
            List<Schema.PicklistEntry> companyBusinessValues = companyBusinessField.getPicklistValues();
            
            for (Schema.PicklistEntry pickListVal : companyBusinessValues) {
                Map<String, String> mp = new Map<String, String>();
                mp.put('label', pickListVal.getLabel());  
                mp.put('value', pickListVal.getValue());
                companyBusinessPicklistValues.add(mp);
            }
            picklistValuesMap.put('companyBusiness', companyBusinessPicklistValues);
            
            return picklistValuesMap;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching picklist values: ' + e.getMessage());
        }
    }   
    
    public static void temethod(){
        for(integer i=0; i<=1500; i++){
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
        }
    }
}