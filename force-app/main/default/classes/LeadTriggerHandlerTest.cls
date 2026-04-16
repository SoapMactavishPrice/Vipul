@isTest
public class LeadTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create Country
        Country__c country = new Country__c(Name = 'India');
        insert country;
        
        // Create State
        State__c state = new State__c(Name = 'Gujarat', Country__c = country.Id);
        insert state;
        
        // Create City
        City__c city = new City__c(Name = 'Ahmedabad', State__c = state.Id);
        insert city;
        
        // Create Area
        Area__c area = new Area__c(Name = 'Navrangpura', City__c = city.Id);
        insert area;
        
        // Create Pin Code
        Pin_Code__c pinCode = new Pin_Code__c(Name = '380009', Area__c = area.Id);
        insert pinCode;
    }
    
    @isTest
    static void testUpdateUsingPinCode() {
        // Fetch required records
        Pin_Code__c pc = [SELECT Id, Area__c, Area__r.City__c, Area__r.City__r.State__c, Area__r.City__r.State__r.Country__c FROM Pin_Code__c LIMIT 1];
        
        // Create lead with Pin_Code__c only
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'PinLead',
            Company = 'Test Co',
            Pin_Code__c = pc.Id
        );
        insert lead;
        
        Test.startTest();
        LeadTriggerHandler.updateLeadAddresses(new List<Lead>{lead});
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testUpdateUsingArea() {
        Area__c area = [SELECT Id, City__c, City__r.State__c, City__r.State__r.Country__c FROM Area__c LIMIT 1];
        
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'AreaLead',
            Company = 'Test Co',
            Area__c = area.Id
        );
        insert lead;
        
        Test.startTest();
        LeadTriggerHandler.updateLeadAddresses(new List<Lead>{lead});
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testUpdateUsingCity() {
        City__c city = [SELECT Id, State__c, State__r.Country__c FROM City__c LIMIT 1];
        
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'CityLead',
            Company = 'Test Co',
            City__c = city.Id
        );
        insert lead;
        
        Test.startTest();
        LeadTriggerHandler.updateLeadAddresses(new List<Lead>{lead});
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testUpdateUsingState() {
        State__c state = [SELECT Id, Country__c FROM State__c LIMIT 1];
        
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'StateLead',
            Company = 'Test Co',
            State__c = state.Id
        );
        insert lead;
        
        Test.startTest();
        LeadTriggerHandler.updateLeadAddresses(new List<Lead>{lead});
        Test.stopTest();
        
    }
    
    @isTest
    static void testNoRelevantFields() {
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'NoFieldLead',
            Company = 'Test Co'
        );
        insert lead;
        
        Test.startTest();
        LeadTriggerHandler.updateLeadAddresses(new List<Lead>{lead});
        Test.stopTest();
        
    }
    
    
    
    @isTest
    static void testHandleLeadConversion() {
        // Step 1: Create Account for conversion target
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Step 2: Create Lead and Contact Info
        Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Status = 'Open - Not Contacted'
        );
        insert lead;
        
        // Create Contact_Information__c related to the Lead
        Contact_Information__c contactInfo = new Contact_Information__c(
            Name = 'Doe',
            First_Name__c = 'John',
            Email__c = 'john@example.com',
            Mobile__c = '9876543210',
            Designation__c = 'Director',
            Department__c = 'Sales',
            Lead__c = lead.Id,
            CurrencyIsoCode = 'USD'
        );
        insert contactInfo;
        
        // Step 3: Simulate Lead Conversion (by updating the same lead record)
        Lead oldLead = lead.clone(false); // Save original state for oldMap
       // lead.IsConverted = true;
      //  lead.ConvertedAccountId = acc.Id;
        lead.Status = 'Closed - Converted';
        update lead;
        
        // Step 4: Prepare input maps (old = before update, new = after update)
        Map<Id, Lead> newLeadMap = new Map<Id, Lead>{ lead.Id => lead };
            Map<Id, Lead> oldLeadMap = new Map<Id, Lead>{ lead.Id => oldLead };
                
                // Step 5: Call the handler method
                Test.startTest();
        LeadTriggerHandler.handleLeadConversion(newLeadMap, oldLeadMap);
        Test.stopTest();
        
        // Step 6: Validate the created Contact
        List<Contact> createdContacts = [
            SELECT FirstName, LastName, Email, MobilePhone, AccountId, Department, Job_Title_Designation__c, CurrencyIsoCode
            FROM Contact WHERE Email = 'john@example.com'
        ];
        
    }
    
    
 

    @isTest
    static void testHandleLeadConversion1() {
        // Create test record types
        Id oppDomesticRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Domestic').getRecordTypeId();
        Id oppIntlRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('International').getRecordTypeId();
        Id accDomesticRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Domestic').getRecordTypeId();
        Id accIntlRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('International').getRecordTypeId();

        // Fetch standard user profile
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser_' + DateTime.now().getTime() + '@example.com',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;	
        
         // Create Country
        Country__c country = new Country__c(Name = 'India');
        insert country;
        
        // Create State
        State__c state = new State__c(Name = 'Gujarat', Country__c = country.Id);
        insert state;
        
        // Create City
        City__c city = new City__c(Name = 'Ahmedabad', State__c = state.Id);
        insert city;
        
        // Create Area
        Area__c area = new Area__c(Name = 'Navrangpura', City__c = city.Id);
        insert area;
        
        // Create Pin Code
        Pin_Code__c pinCode = new Pin_Code__c(Name = '380009', Area__c = area.Id);
        insert pinCode;
        
        // Create Account (for Account-only lead conversion case)
        Account accOnly = new Account(Name = 'Converted Only Account');
        insert accOnly;

        // Create Contact (for both cases)
        Contact con = new Contact(LastName = 'Converted Contact');
        insert con;

        // Case 1: Lead converted with Opportunity
        Account acc1 = new Account(Name = 'Account For Opp Lead');
        insert acc1;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc1.Id
        );
        insert opp;

        Lead leadWithOpp = new Lead(
            FirstName = 'Test',
            LastName = 'WithOpp',
            Company = 'Test Co',
           // IsConverted = true,
           // ConvertedOpportunityId = opp.Id,
           // ConvertedAccountId = acc1.Id,
          //  ConvertedContactId = con.Id,
            OwnerId = testUser.Id,
            Country__c = country.Id,
            Lead_Type__c = 'Domestic',
            Description = 'Test Lead Desc',
            Email = 'test@example.com',
            MobilePhone = '1234567890',
            Inco_Terms__c = 'FOB'
        );
        insert leadWithOpp;
        Id standardPBId = Test.getStandardPricebookId();

Product2 prod = new Product2(
    Name = 'Test Product',
    IsActive = true
);
insert prod;

PricebookEntry pbe = new PricebookEntry(
    Product2Id = prod.Id,
    Pricebook2Id = standardPBId,
    UnitPrice = 100,
    IsActive = true
);
insert pbe;

              LeadStatus convertedStatus = [
    SELECT MasterLabel
    FROM LeadStatus
    WHERE IsConverted = true
    LIMIT 1
];
        // Case 2: Lead converted without Opportunity
        Lead leadOnlyAcc = new Lead(
            FirstName = 'Test2',
            LastName = 'OnlyAcc',
            Company = 'Test Co 2',
          //  IsConverted = true,
          //  ConvertedAccountId = accOnly.Id,
           // ConvertedContactId = con.Id,
            Lead_Type__c = 'International',
            Description = 'Account only conversion',
            Email = 'onlyacc@example.com',
            MobilePhone = '9999999999',
            Inco_Terms__c = 'CIF'
        );
        insert leadOnlyAcc;
        try{
            
        
         Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadOnlyAcc.Id);
            lc.setConvertedStatus(convertedStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(false);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        }catch(exception e){
            
        }
        Test.startTest();
        LeadTriggerHandler.handleLeadConversion(new List<Lead>{leadWithOpp, leadOnlyAcc});
        Test.stopTest();

        // Validate updated Opportunity
        Opportunity updatedOpp = [SELECT Id, Who_will_attend__c, Customer_Type__c, Country__c, RecordType.DeveloperName, Inco_Terms__c
                                  FROM Opportunity WHERE Id = :opp.Id];
       

        // Validate updated Account (from opportunity-linked lead)
        Account updatedAcc1 = [SELECT Id, Description, Contact__c, Contact_s_Email__c, Contact_s_Mobile__c, Contact_Name__c, RecordType.DeveloperName
                               FROM Account WHERE Id = :acc1.Id];
        

        // Validate updated Account (from lead-only conversion)
        Account updatedAccOnly = [SELECT Id, Description, Contact__c, Contact_s_Email__c, Contact_s_Mobile__c, Contact_Name__c, RecordType.DeveloperName
                                  FROM Account WHERE Id = :accOnly.Id];
        
    }
    

    // Helper method to create a test user
    private static User createTestUser(String division, String profileName) {
        Profile profile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User user = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            User_Division__c = division
        );
        insert user;
        return user;
    }

    @isTest
    static void testUpdateContactFieldOnOpportunity() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Contact
        Contact con = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert con;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        // Create a converted Lead
        Lead lead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company'
           // IsConverted = true
           // ConvertedOpportunityId = opp.Id,
           // ConvertedContactId = con.Id
        );
        insert lead;

        Test.startTest();
        LeadTriggerHandler.updateContactFieldOnOpportunity(new List<Lead>{ lead });
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Contact__c FROM Opportunity WHERE Id = :opp.Id];
    }

    @isTest
    static void testSetLeadTypeBasedOnUserDivision() {
        // Create a user with Domestic division and non-admin profile
        User testUser = createTestUser('Domestic', 'Standard User');

        // Run test logic in the context of that user
        System.runAs(testUser) {
            Lead lead1 = new Lead(FirstName = 'Alice', LastName = 'Domestic', Company = 'TestCo');
            Lead lead2 = new Lead(FirstName = 'Bob', LastName = 'Domestic', Company = 'TestCo');

            List<Lead> leads = new List<Lead>{ lead1, lead2 };

            Test.startTest();
            LeadTriggerHandler.setLeadTypeBasedOnUserDivision(leads);
            Test.stopTest();

            for (Lead l : leads) {
                System.assertEquals('Domestic', l.Lead_Type__c);
            }
        }

        // Create a user with International division
        User intlUser = createTestUser('International', 'Standard User');

        System.runAs(intlUser) {
            Lead intlLead = new Lead(FirstName = 'Carl', LastName = 'Intl', Company = 'TestCo');

            List<Lead> leads = new List<Lead>{ intlLead };

           // Test.startTest();
            LeadTriggerHandler.setLeadTypeBasedOnUserDivision(leads);
           // Test.stopTest();

        }
    }  
    

    @isTest
    static void testUpdateSampleRequestFields() {
        // Step 1: Create test Account and Opportunity to simulate conversion result
        Account acc = new Account(Name = 'Converted Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Converted Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15)
        );
        insert opp;

        // Step 2: Create original (non-converted) Lead
        Lead oldLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            IsConverted = false
        );
        insert oldLead;

        // Step 3: Create Sample_Out_Request__c related to the Lead
        Sample_Out_Request__c sampleRequest = new Sample_Out_Request__c(
            Lead__c = oldLead.Id
        );
        insert sampleRequest;

        // Step 4: Simulate conversion (update the Lead to IsConverted = true)
        Lead convertedLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :oldLead.Id];
       // convertedLead.IsConverted = true;
        //convertedLead.ConvertedAccountId = acc.Id;
       // convertedLead.ConvertedOpportunityId = opp.Id;
        update convertedLead;

        // Step 5: Prepare new and old lead maps
        Map<Id, Lead> oldMap = new Map<Id, Lead>{ oldLead.Id => oldLead };
        List<Lead> newList = [SELECT Id, ConvertedAccountId, ConvertedOpportunityId, IsConverted FROM Lead WHERE Id = :oldLead.Id];

        // Step 6: Run the method
        Test.startTest();
        LeadTriggerHandler.UpdateSampleRequestFields(newList, oldMap);
        Test.stopTest();

        // Step 7: Verify the Sample_Out_Request__c is updated correctly
        Sample_Out_Request__c updatedRequest = [
            SELECT Id, Company_Name__c, Enquiry_Name__c FROM Sample_Out_Request__c WHERE Id = :sampleRequest.Id
        ];

       
    }
    /* sai Prasad *88888888888888888888888 */
    
   @IsTest
static void testHandleLeadConversion_CreateContacts() {

    /* ---------- Test Data ---------- */

    // Create Account (used after conversion)
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    // Create Lead (NOT converted yet)
    Lead ld = new Lead(
        LastName = 'Test Lead',
        Company = 'Test Company',
        Status = 'Open'
    );
    insert ld;

    // Create Contact Information related to Lead
    Contact_Information__c ci = new Contact_Information__c(
        Name = 'Doe',
        First_Name__c = 'John',
        Email__c = 'john@test.com',
        Mobile__c = '9999999999',
        Department__c = 'Sales',
        Lead__c = ld.Id
    );
    insert ci;
    LeadStatus convertedStatus = [
    SELECT MasterLabel
    FROM LeadStatus
    WHERE IsConverted = true
    LIMIT 1
];



    Database.LeadConvert lc = new Database.LeadConvert();
            lc.setConvertedStatus(convertedStatus.MasterLabel);

    lc.setLeadId(ld.Id);
    lc.setAccountId(acc.Id);
    lc.setDoNotCreateOpportunity(true);

    Lead oldLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :ld.Id];

    Test.startTest();
   Database.convertLead(lc);
    Test.stopTest();

    Lead newLead = [
        SELECT Id, IsConverted, ConvertedAccountId
        FROM Lead
        WHERE Id = :ld.Id
    ];


    Map<Id, Lead> newMap = new Map<Id, Lead>{ newLead.Id => newLead };
    Map<Id, Lead> oldMap = new Map<Id, Lead>{ oldLead.Id => oldLead };

   // Test.startTest();
    LeadTriggerHandler.handleLeadConversion(newMap, oldMap);
   // Test.stopTest();

    /* ---------- Assertions ---------- */

    List<Contact> contacts = [
        SELECT FirstName, LastName, Email, MobilePhone, AccountId
        FROM Contact
        WHERE AccountId = :newLead.ConvertedAccountId
    ];

   
}

        
     
}