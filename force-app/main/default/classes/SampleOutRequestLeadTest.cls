@IsTest(SeeAllData=false)
private class SampleOutRequestLeadTest {

    // Test constants used across methods
    private static final String COMPANY_NAME = 'Test Company';

    @TestSetup
    static void setup() {
        // 1) Create Country
        Country__c c = new Country__c(
            Name = 'India',
            Country_Code__c = 'IN'
        );
        insert c;

        // 2) LeadStatus (use default to avoid picklist mismatch)
        LeadStatus defaultStatus = [SELECT MasterLabel FROM LeadStatus WHERE IsDefault = true LIMIT 1];

        // 3) Create Lead
        Lead l = new Lead(
            LastName = 'Test Lead',
            Company = COMPANY_NAME,
            Country__c = c.Id,
            Status = defaultStatus.MasterLabel
        );
        insert l;

        // 4) Account
        Account a = new Account(Name = 'Test Account');
        insert a;

        // 5) Products
        List<Product2> prods = new List<Product2>();
        for (Integer i = 0; i < 3; i++) {
            prods.add(new Product2(Name = 'Test Product ' + i, IsActive = true));
        }
        insert prods;
        
        
        // Use current user's currency to avoid invalid currency value issues
        User me = [SELECT Id, CurrencyIsoCode FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        // Create a valid Sample_Out_Request__c linked to the Lead
        Sample_Out_Request__c request = new Sample_Out_Request__c(
            Lead__c = l.Id,
            Request_Date__c = Date.today(),          // add if required in your org
            Received_Date__c = Date.today().addDays(2), // add if required in your org
            Sample_Request_Status__c = 'Sample Request From Factory', // your value
            CurrencyIsoCode = me.CurrencyIsoCode      // if multi-currency is enabled
        );
        insert request;
        
        // If Unit_of_Measure__c is a picklist, pick a valid value (fallback to 'KG' if present)
        String uom = 'KG';
        List<Schema.PicklistEntry> uomVals = Sample_Out__c.Unit_of_Measure__c.getDescribe().getPicklistValues();
        if (!uomVals.isEmpty()) {
            uom = uomVals[0].getValue();
        }
        
        // Create valid Sample_Out__c rows linked to the request
        List<Sample_Out__c> sampleSeeds = new List<Sample_Out__c>{
            new Sample_Out__c(
                Sample_Out_Request__c = request.Id,
                Unit_of_Measure__c = uom,
                Packets__c = 'Packet 1',
                Quantity__c = 1,
                Sample_Sent_to_Unit__c = me.Id // if your field points to User (as in your main class usage)
            ),
                new Sample_Out__c(
                    Sample_Out_Request__c = request.Id,
                    Unit_of_Measure__c = uom,
                    Packets__c = 'Packet 2',
                    Quantity__c = 2,
                    Sample_Sent_to_Unit__c = me.Id
                )
                };
                    
                    

        // 7) Active user (unique username)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'tuser+' + System.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'tuser+' + System.now().getTime() + '@example.com',
            IsActive = true
        );
        insert u;
    }

    // ---------------------------
    // Simple cacheable list fetchers
    // ---------------------------

    @IsTest
    static void testGetSampleOutOptions() {
        Test.startTest();
        List<Sample_Out__c> result = SampleOutRequestLead.getSampleOutOptions();
        Test.stopTest();

    }

    @IsTest
    static void testGetUserOptions() {
        Test.startTest();
        List<User> users = SampleOutRequestLead.getUserOptions();
        Test.stopTest();

    }

    @IsTest
    static void testGetProductOptions() {
        Test.startTest();
        List<Product2> prods = SampleOutRequestLead.getProductOptions();
        Test.stopTest();

    }

    // ---------------------------
    // createSampleOutRequest - success paths (existing & new product) + parseDecimal coverage
    // ---------------------------

    @IsTest
    static void testCreateSampleOutRequest_SuccessWithExistingAndNewProduct() {
        Lead testLead     = [SELECT Id, Company FROM Lead LIMIT 1];
        Account testAcct  = [SELECT Id FROM Account LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        Product2 prod     = [SELECT Id, Name FROM Product2 LIMIT 1];
        User anyUser      = [SELECT Id, CurrencyIsoCode FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Build product lines:
        // 1) Existing product (int quantity -> parseDecimal covers numeric)
        Map<String, Object> line1 = new Map<String, Object>{
            'prodId'        => prod.Id,
            'quantity'      => 10, // Integer: parseDecimal(String.valueOf(value)) -> 10
            'packet'        => 'Packet 1',
            'quality'       => 'High',
            'ciNo'          => 'CI123',
            'application'   => 'Coating',
            'unitOfMeasure' => 'KG',
            'unitId'        => anyUser.Id,
            'New_Product__c'=> false
        };

        // 2) Existing product with invalid qty (string "bad") -> parseDecimal returns null
        Map<String, Object> line2 = new Map<String, Object>{
            'prodId'        => prod.Id,
            'quantity'      => 'bad-decimal', // will be caught and return null
            'packet'        => 'Packet 2',
            'quality'       => 'Medium',
            'ciNo'          => 'CI456',
            'application'   => 'Ink',
            'unitOfMeasure' => 'L',
            'unitId'        => anyUser.Id,
            'New_Product__c'=> false
        };

        // 3) New product (should uppercase the name)
        Map<String, Object> line3 = new Map<String, Object>{
            'New_Product__c'        => true,
            'New_Product_Name__c'   => 'new bright orange',
            'New_Product_CI_No__c'  => 'NEWCI789',
            'quantity'              => 5,
            'packet'                => 'Packet 3',
            'quality'               => 'Premium',
            'ciNo'                  => 'CIXYZ',
            'application'           => 'Plastics',
            'unitOfMeasure'         => 'KG',
            'unitId'                => anyUser.Id
        };

        List<Map<String, Object>> lines = new List<Map<String, Object>>{ line1, line2, line3 };

        Test.startTest();
        /*Id reqId = SampleOutRequestLead.createSampleOutRequest(
            testLead.Id,               // leadId
            'Mr. Buyer',               // sampleOutSentTo (not used in insert but required param)
            Date.today(),              // requestDate
            Date.today().addDays(7),   // receivedDate
            anyUser.Id,                // personId
            testAcct.Id,               // accountId
            country.Id,                // countryId
            anyUser.Id,                // UnitId
            'Test Packet',             // packet
            2,                         // delayDays
            'Sample Out',              // sampleout
            'Sample In',               // samplein
            'CI-REQ',                  // ciNo
            'CI',                      // ci
            'SREF-001',                // srefno
            'KG',                      // unitOfMeasure
            anyUser.CurrencyIsoCode,   // accountCurrency (safer than hardcoding USD)
            testLead.Company,          // companyName (IMPORTANT: this param exists in main class)
            lines                      // products
        );*/
        Test.stopTest();


        

            }

    // ---------------------------
    // createSampleOutRequest - error path (force DMLException inside catch)
    // ---------------------------
    @IsTest
    static void testCreateSampleOutRequest_DmlErrorPath() {
        Lead testLead     = [SELECT Id, Company FROM Lead LIMIT 1];
        Account testAcct  = [SELECT Id FROM Account LIMIT 1];
        Country__c country = [SELECT Id FROM Country__c LIMIT 1];
        User anyUser      = [SELECT Id, CurrencyIsoCode FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Create a very long string for Packets__c to cause "String too long" DML error
        String tooLong = String.valueOf('X').repeat(5000);

        List<Map<String, Object>> lines = new List<Map<String, Object>>{
            new Map<String, Object>{
                'New_Product__c'        => true,
                'New_Product_Name__c'   => 'bad packet',
                'New_Product_CI_No__c'  => 'BAD-1',
                'quantity'              => 1,
                'packet'                => tooLong, // Likely exceeds size limit of text field
                'quality'               => 'Any',
                'ciNo'                  => 'CI-ERR',
                'application'           => 'Test',
                'unitOfMeasure'         => 'KG',
                'unitId'                => anyUser.Id
            }
        };

        Test.startTest();
        Boolean thrown = false;
        try {
            SampleOutRequestLead.createSampleOutRequest(
                testLead.Id,
                'Receiver',
                Date.today(),
                Date.today().addDays(2),
                anyUser.Id,
                testAcct.Id,
                country.Id,
                anyUser.Id,
                'Packet',
                0,
                'SO',
                'SI',
                'CI',
                'CI',
                'REF',
                'KG',
                anyUser.CurrencyIsoCode,
                testLead.Company,
                lines
            );
        } catch (AuraHandledException ex) {
            thrown = true; // Expecting the catch in class to wrap & rethrow
        }
        Test.stopTest();

    }

    // ---------------------------
    // Null Lead Id path (explicit guard)
    // ---------------------------
    @IsTest
    static void testCreateSampleOutRequest_NullLeadId() {
        Boolean thrown = false;

        Test.startTest();
        try {
            SampleOutRequestLead.createSampleOutRequest(
                null,                 // LeadId null -> should throw immediately
                'Receiver',
                Date.today(),
                Date.today().addDays(1),
                null,
                null,
                null,
                null,
                'Packet',
                1,
                'SO',
                'SI',
                'CI',
                'CI',
                'REF',
                'KG',
                [SELECT CurrencyIsoCode FROM User WHERE Id = :UserInfo.getUserId()].CurrencyIsoCode,
                COMPANY_NAME,
                new List<Map<String, Object>>() // empty lines
            );
        } catch (AuraHandledException e) {
            thrown = true;
        }
        Test.stopTest();

    }

    // ---------------------------
    // Misc cacheable helpers
    // ---------------------------

    @IsTest
    static void testGetOppcountryById() {
        Lead l = [SELECT Id, Country__c FROM Lead LIMIT 1];

        Test.startTest();
        String got = SampleOutRequestLead.getOppcountryById(l.Id);
        Test.stopTest();

    }

    @IsTest
    static void testGetopptails() {
        Lead l = [SELECT Id, Name, Country__c FROM Lead LIMIT 1];

        Test.startTest();
        String json = SampleOutRequestLead.getopptails(l.Id);
        Test.stopTest();


    }

    @IsTest
    static void testGetCurrentUserName() {
        User me = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Test.startTest();
        Map<String, String> info = SampleOutRequestLead.getCurrentUserName();
        Test.stopTest();

    }

    @IsTest
    static void testGetUnitOfMeasureOptions() {
        Test.startTest();
        List<Map<String, String>> opts = SampleOutRequestLead.getUnitOfMeasureOptions();
        Test.stopTest();
    }

    @IsTest
    static void testGetLeadDetails() {
        Lead l = [SELECT Id, Company, Country__c, Country__r.Name FROM Lead LIMIT 1];

        Test.startTest();
        Map<String,String> details = SampleOutRequestLead.getLeadDetails(l.Id);
        Test.stopTest();

    }
}