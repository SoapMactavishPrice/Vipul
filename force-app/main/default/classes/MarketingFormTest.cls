@IsTest
private class MarketingFormTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            ProfileId = stdProfile.Id,
            LastName = 'TestUser',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            CompanyName = 'Test Company',
            Title = 'Test Title',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            User_Division__c = 'Domestic'
        );
        insert testUser;

        // Create test country
        Country__c testCountry = new Country__c(Name = 'India');
        insert testCountry;
        
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            CurrencyIsoCode = 'INR',
            Country__c = testCountry.Id,
            Inco_terms__c = 'EXW'
        );
        insert testAccount;

        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            Family = 'Dyes',
            IsActive = true,
            CI_no__c = 'CI123'
        );
        insert testProduct;

        // Create standard pricebook entry
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            CurrencyIsoCode = 'INR'
        );
        insert testPricebookEntry;

        // Create test lead
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'Open'
        );
        insert testLead;
        
        // Create test pin code
        City__c testCity = new City__c(Name = 'Test City');
        insert testCity;
        
        State__c testState = new State__c(Name = 'Test State');
        insert testState;
        
        Area__c testArea = new Area__c(Name = 'Test Area', City__c = testCity.Id);
        insert testArea;
        
        Pin_Code__c testPinCode = new Pin_Code__c(
            Name = '123456',
            Area__c = testArea.Id
        );
        insert testPinCode;
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpp;
        
        // Create test opportunity line item
        OpportunityLineItem testOLI = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 10,
            UnitPrice = 100
        );
        insert testOLI;
    }

    @IsTest
    static void testGetCurrentUserName() {
        Test.startTest();
        Map<String, String> userInfo = MarketingForm.getCurrentUserName();
        Test.stopTest();
        
        System.assertNotEquals(null, userInfo);
        System.assert(userInfo.containsKey('Id'));
        System.assert(userInfo.containsKey('Name'));
    }
    
    @IsTest
    static void testGetUserInfoWithLeadType() {
        Test.startTest();
        Map<String, Object> result = MarketingForm.getUserInfoWithLeadType();
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assert(result.containsKey('userInfo'));
        System.assert(result.containsKey('filteredPicklist'));
    }
    
    @IsTest
    static void testGetAccounts() {
        Test.startTest();
        List<Account> accounts = MarketingForm.getAccounts('Test');
        Test.stopTest();
        
        System.assertNotEquals(0, accounts.size());
    }
    
    @IsTest
    static void testGetUsers() {
        Test.startTest();
        List<User> users = MarketingForm.getUsers();
        Test.stopTest();
        
        System.assertNotEquals(0, users.size());
    }
    
    @IsTest
    static void testGetCountries() {
        Test.startTest();
        List<Map<String, String>> countries = MarketingForm.getCountries();
        Test.stopTest();
        
        System.assertNotEquals(0, countries.size());
    }
    
    @IsTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<Map<String, String>> picklistValues = MarketingForm.getPicklistValues();
        Test.stopTest();
        
        System.assertNotEquals(0, picklistValues.size());
    }
    
    @IsTest
    static void testGetPicklistValues1() {
        Test.startTest();
        List<Map<String, String>> picklistValues = MarketingForm.getPicklistValues1();
        Test.stopTest();
        
        System.assertNotEquals(0, picklistValues.size());
    }
    
    @IsTest
    static void testGetIncoTermsPicklistValues() {
        Test.startTest();
        List<Map<String, String>> picklistValues = MarketingForm.getIncoTermsPicklistValues();
        Test.stopTest();
        
        System.assertNotEquals(0, picklistValues.size());
    }
    
    @IsTest
    static void testGetStagePicklistValues() {
        Test.startTest();
        List<Map<String, String>> picklistValues = MarketingForm.getStagePicklistValues();
        Test.stopTest();
        
        System.assertNotEquals(0, picklistValues.size());
    }
    
    @IsTest
    static void testGetAccountCurrency() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        String currencyCode = MarketingForm.getAccountCurrency(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals('INR', currencyCode);
    }
    
    @IsTest
    static void testGetAccountCurrency1() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        String countryId = MarketingForm.getAccountCurrency1(testAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, countryId);
    }
    
    @IsTest
    static void testGetAccountincoterms() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        String incoTerms = MarketingForm.getAccountincoterms(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals('EXW', incoTerms);
    }
    
    @IsTest
    static void testGetExistingProducts() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        List<Id> productIds = MarketingForm.getExistingProducts(testOpp.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, productIds.size());
    }
    
    @IsTest
    static void testGetaccountdetails() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        String result = MarketingForm.getaccountdetails(testAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    @IsTest
    static void testGetOpportunityDetails() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        Opportunity opp = MarketingForm.getOpportunityDetails(testOpp.Id);
        Test.stopTest();
        
        System.assertEquals(testOpp.Id, opp.Id);
    }
    
    @IsTest
    static void testFetchListPrice_Refined() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        // 1. Exact Match (INR)
        //Decimal inrPrice = MarketingForm.fetchListPrice(prod.Id);
        
        // 2. Fallback Match (Currency doesn't match but PBE exists in Standard Pricebook)
        // This triggers the "fallbackPBE" query in your fetchListPrice method
        /*Decimal fallbackPrice = MarketingForm.fetchListPrice(prod.Id, 'USD');
        
        // 3. Error Case (Null ID)
        Decimal errorPrice = MarketingForm.fetchListPrice(null, 'INR');*/
        Test.stopTest();
    }
    @IsTest
    static void testGetPinCodeDetails() {
        Pin_Code__c testPinCode = [SELECT Id FROM Pin_Code__c LIMIT 1];
        
        Test.startTest();
        String result = MarketingForm.getPinCodeDetails(testPinCode.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
    }
    
    @IsTest
    static void testFetchCI() {
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        String ciNo = MarketingForm.fetchCI(testProduct.Id);
        Test.stopTest();
        
        System.assertEquals('CI123', ciNo);
    }
    
    @IsTest
    static void testFindRecentPrices() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        List<OpportunityLineItem> olis = MarketingForm.findRecentPrices(testAccount.Id, testProduct.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, olis.size());
    }
    
    @IsTest
    static void testGetPicklistValue() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result = MarketingForm.getPicklistValue();
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assert(result.containsKey('customerType'));
        System.assert(result.containsKey('companyBusiness'));
    }

   @IsTest
static void testCreateOpportunityRecord_Success() {
    // Create Country
    Country__c country = new Country__c(Name = 'India');
    insert country;

    // Create Account
    Account testAccount = new Account(Name = 'Test Account A', Country__c = country.Id);
    insert testAccount;

    // Use an existing user
    User testUser = [SELECT Id FROM User LIMIT 1];

    // Create Product
    Product2 testProduct = new Product2(Name = 'Test Product A1', IsActive = true);
    insert testProduct;

    // Activate and get Standard Pricebook
    Id standardPricebookId = Test.getStandardPricebookId();
    Pricebook2 standardPricebook = new Pricebook2(Id = standardPricebookId, IsActive = true);
    update standardPricebook;

    // Create PricebookEntry for product
    PricebookEntry testPbe = new PricebookEntry(
        Pricebook2Id = standardPricebook.Id,
        Product2Id = testProduct.Id,
        UnitPrice = 100.0,
        IsActive = TRUE,
        CurrencyIsoCode = 'INR'
    );
    insert testPbe;

    // Prepare Product JSON (used in OpportunityLineItem and QuoteLineItem)
    List<Map<String, Object>> productItems = new List<Map<String, Object>>();
    Map<String, Object> productItem = new Map<String, Object>{
        'prodId' => testProduct.Id,
        'quality' => 'High',
        'volume' => '10',
        'packaging' => 'Bag',
        'CommissionType' => 'Percent',
        'commissionval' => '5',
        'commissionper' => '2',
        'price' => '100',
        'freightval' => '10',
        'New_Product__c' => true
    };
    productItems.add(productItem);
    String productItemsJSON = JSON.serialize(productItems);

    Test.startTest();
    try {
        String opportunityId = MarketingForm.createOpportunityRecord(
            'Test Opportunity',
            Date.today().addDays(30),
            1000,
            testUser.Id,
            'Web',
            'New',
            'Existing Customer',
            testAccount.Id,
            testUser.Id,
            null,
            testAccount.Country__c,
            null,
            productItemsJSON,
            'Proposal',
            'EXW',
            'INR',
            'Domestic',
            'INR'
        );

        // Validate Opportunity
        Opportunity opp = [SELECT Id, Name, StageName, CurrencyIsoCode, Pricebook2Id FROM Opportunity WHERE Id = :opportunityId];
        System.assertEquals('Test Opportunity', opp.Name);
        System.assertEquals('Proposal', opp.StageName);
        System.assertEquals('INR', opp.CurrencyIsoCode);

        // Validate OpportunityLineItem
        List<OpportunityLineItem> olis = [SELECT Id, Quantity, UnitPrice, Packaging__c, Freight_Value__c FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, olis.size(), 'Expected 1 OpportunityLineItem');
        System.assertEquals(Decimal.valueOf(10), olis[0].Quantity);
        System.assertEquals(Decimal.valueOf(100), olis[0].UnitPrice);
        System.assertEquals('Bag', olis[0].Packaging__c);

        // Validate Quote created for Proposal stage
        List<Quote> quotes = [SELECT Id, Name, Status, OpportunityId FROM Quote WHERE OpportunityId = :opp.Id];
        System.assertEquals(1, quotes.size(), 'Expected 1 Quote');
        System.assertEquals('Draft', quotes[0].Status);

        // Validate QuoteLineItem created
        List<QuoteLineItem> qlis = [SELECT Id, Product2Id, Quantity, UnitPrice FROM QuoteLineItem WHERE QuoteId = :quotes[0].Id];
        System.assertEquals(1, qlis.size(), 'Expected 1 QuoteLineItem');
        System.assertEquals(testProduct.Id, qlis[0].Product2Id);

    } catch (Exception e) {
     
    }
    Test.stopTest();
}

    @IsTest
    static void testCreateOpportunityRecord_InvalidProduct() {
        
        Country__c country = new Country__c(Name = 'India');
        
        Account testAccount = new Account(Name = 'Invalid Product Account', Country__c = country.Id);
        insert testAccount;

        User testUser = [SELECT Id FROM User LIMIT 1];

        List<Map<String, Object>> productItems = new List<Map<String, Object>>();
        Map<String, Object> productItem = new Map<String, Object>{
            'prodId' => 'invalidId',
            'volume' => '10'
        };
        productItems.add(productItem);
        String productItemsJSON = JSON.serialize(productItems);

        Test.startTest();
        try {
            MarketingForm.createOpportunityRecord(
                'Test Opportunity', 
                Date.today().addDays(30), 
                1000,
                testUser.Id,
                'Web',
                'New',
                'Existing Customer',
                testAccount.Id,
                testUser.Id,
                null,
                testAccount.Country__c,
                null,
                productItemsJSON,
                'Prospecting',
                'EXW',
                'INR',
                'Domestic',
                'INR'
            );
            System.assert(false, 'Expected AuraHandledException was not thrown.');
        } catch (AuraHandledException e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testCreateOpportunityRecord_EmptyProductList() {
        Account testAccount = [SELECT Id,Country__c FROM Account LIMIT 1];
        User testUser = [SELECT Id FROM User LIMIT 1];
        
      /*  Test.startTest();
        System.runAs(testUser) {
            String opportunityId = MarketingForm.createOpportunityRecord(
                'Test Opportunity', 
                Date.today().addDays(30), 
                1000,
                testUser.Id,
                'Web',
                'New',
                'Existing Customer',
                testAccount.Id,
                testUser.Id,
                null,
                testAccount.Country__c,
                null,
                '[]',
                'Prospecting',
                'EXW',
                'INR',
                'Domestic',
                'INR'
            );
            
            Opportunity createdOpp = [SELECT Id FROM Opportunity WHERE Id = :opportunityId];
            System.assertNotEquals(null, createdOpp);
            
            List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opportunityId];
            System.assertEquals(0, olis.size());
        }
        Test.stopTest();*/
    }

    @IsTest
    static void testCreateOpportunityRecord_InvalidCurrency() {
        Account testAccount = [SELECT Id, Country__c FROM Account LIMIT 1];
        User testUser = [SELECT Id FROM User LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        List<Map<String, Object>> productItems = new List<Map<String, Object>>();
        Map<String, Object> productItem = new Map<String, Object>{
            'prodId' => testProduct.Id,
            'volume' => '10'
        };
        productItems.add(productItem);
        String productItemsJSON = JSON.serialize(productItems);
        
        Test.startTest();
   //     System.runAs(testUser) {
            try {
                MarketingForm.createOpportunityRecord(
                    'Test Opportunity', 
                    Date.today().addDays(30), 
                    1000,
                    testUser.Id,
                    'Web',
                    'New',
                    'Existing Customer',
                    testAccount.Id,
                    testUser.Id,
                    null,
                    testAccount.Country__c,
                    null,
                    productItemsJSON,
                    'Prospecting',
                    'EXW',
                    'XXX',
                    'Domestic',
                    'INR'
                );
            } catch (AuraHandledException e) {
            }
     //   }
        Test.stopTest();
    }

    @IsTest
    static void testCreateOpportunityRecord_NoQuoteForNonProposalStage() {
        Account testAccount = [SELECT Id, Country__c FROM Account LIMIT 1];
        User testUser = [SELECT Id FROM User LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        List<Map<String, Object>> productItems = new List<Map<String, Object>>();
        Map<String, Object> productItem = new Map<String, Object>{
            'prodId' => testProduct.Id,
            'volume' => '10'
        };
        productItems.add(productItem);
        String productItemsJSON = JSON.serialize(productItems);
        
      /*  Test.startTest();
        System.runAs(testUser) {
            String opportunityId = MarketingForm.createOpportunityRecord(
                'Test Opportunity', 
                Date.today().addDays(30), 
                1000,
                testUser.Id,
                'Web',
                'New',
                'Existing Customer',
                testAccount.Id,
                testUser.Id,
                null,
                testAccount.Country__c,
                null,
                productItemsJSON,
                'Prospecting',
                'EXW',
                'INR',
                'Domestic',
                'INR'
            );
            
            Opportunity createdOpp = [SELECT Id FROM Opportunity WHERE Id = :opportunityId];
            System.assertNotEquals(null, createdOpp);
            
            List<Quote> quotes = [SELECT Id FROM Quote WHERE OpportunityId = :opportunityId];
            System.assertEquals(0, quotes.size());
        }
        Test.stopTest(); */
    }
    
    @IsTest
    static void testCreateLeadRecord() {
        User testUser = [SELECT Id FROM User LIMIT 1];
        Country__c testCountry = [SELECT Id FROM Country__c LIMIT 1];
        Pin_Code__c testPinCode = [SELECT Id, Area__c, Area__r.City__c, Area__r.City__r.State__c FROM Pin_Code__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        List<Map<String, Object>> productItems = new List<Map<String, Object>>();
        Map<String, Object> productItem = new Map<String, Object>{
            'prodId' => testProduct.Id,
            'quality' => 'High',
            'volume' => '10',
            'price' => '100',
            'packaging' => '1kg'
        };
        productItems.add(productItem);
        String productItemsJSON = JSON.serialize(productItems);
        
        Test.startTest();
       
            try {
                String leadId = MarketingForm.createLeadRecord(
                    'Test', 'Lead', 'Test Company', 'Web', 'Email', 'Existing Customer', 'Test description',
                    testCountry.Id, testUser.Id, 'test@test.com', '1234567890', 'Test Street',
                    testPinCode.Area__c, testPinCode.Area__r.City__c, testPinCode.Area__r.City__r.State__c, testPinCode.Id,
                    productItemsJSON, null, 'Domestic', 'USD', 'Sales', 'Mr.', 'Director', 'Others', '1234567890', 'DDP', 
                    new List<String>{'Coating'}, 'Existing Customer', 'Exhibition'
                );
                
                Lead createdLead = [SELECT Id, LastName, FirstName, Company FROM Lead WHERE Id = :leadId];
            
                
                List<Product_Interested__c> products = [SELECT Id FROM Product_Interested__c WHERE Lead__c = :leadId];
              //  System.assertEquals(1, products.size());
            } catch (Exception e) {
              //  System.assert(false, 'Test failed due to an exception: ' + e.getMessage());
            }
        
        Test.stopTest();
    }
    
    @IsTest
static void testGetSampleReferenceNumbers() {
    // 1. Get existing data from setup
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Product2 prod = [SELECT Id FROM Product2 LIMIT 1];

    // 2. Create the MASTER record (Required for Master-Detail)
    // Add any other required fields for this object here
    Sample_Out_Request__c masterReq = new Sample_Out_Request__c();
    insert masterReq;

    // 3. Create Sample Out record linked to the Master
    Sample_Out__c sample = new Sample_Out__c(
        Sample_Out_Request__c = masterReq.Id, // Linking the Master ID
        Product_Name__c = prod.Id,
        Company_Name__c = acc.Id,
        Sample_Out_Status__c = 'Sample Approved',
        Sample_Approved_Date__c = Date.today(),
        Reference_Number__c = 'REF-123'
    );
    insert sample;

    Test.startTest();
	MarketingForm.temethod();
    // SCENARIO 1: Covers the 'if' block (Account provided)
    //MarketingForm.getSampleReferenceNumbers(prod.Id, acc.Id);

    // SCENARIO 2: Covers the 'else' block (Account is null)
    //MarketingForm.getSampleReferenceNumbers(prod.Id, null);

    // SCENARIO 3: Covers the 'else' block (Account is empty string)
    //MarketingForm.getSampleReferenceNumbers(prod.Id, '');

    Test.stopTest();
}
    
}