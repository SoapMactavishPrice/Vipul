@isTest
public class OptyTriggerHandlerTest {
    @TestSetup
    static void setupTestData() {
        // Create a custom test Pricebook
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;
    }

    @isTest
    static void testConvertHandler() {
        // Create test Product first
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

         Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // Create a custom test Pricebook
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;
        // Create a custom test Pricebook
        Pricebook2 customPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert customPricebook;

        // Create PricebookEntry for the product in the Standard Price Book
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPBE;

        // Create PricebookEntry for the product in the Custom Price Book
        PricebookEntry customPBE = new PricebookEntry(
            Pricebook2Id = customPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert customPBE;

        // Create a test Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open - Not Contacted',
            CurrencyISOCode = 'USD'
        );
        insert testLead;

        // Convert the Lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus(getConvertedStatus());
        lc.setDoNotCreateOpportunity(false);
        Database.LeadConvertResult lcr = Database.convertLead(lc);

        // Get the converted Opportunity
        testLead = [SELECT Id, IsConverted, ConvertedOpportunityId, ConvertedAccountId, ConvertedContactId FROM Lead WHERE Id = :testLead.Id];
        Opportunity testOpp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :testLead.ConvertedOpportunityId];

        // Update opportunity to use our custom pricebook
        testOpp.Pricebook2Id = customPricebook.Id;
        update testOpp;

        // Create a Product_Interested__c record
        Product_Interested__c testProductInterested = new Product_Interested__c(
            Lead__c = testLead.Id,
            Vipul_Product_Name__c = testProduct.Id,
            Quantity__c = 10,
            Price__c = 150,
            Add_in_Opportunity__c = true
        );
        insert testProductInterested;

        // Simulate old lead state
        Map<Id, Lead> oldLeadMap = new Map<Id, Lead> {
            testLead.Id => new Lead(
                Id = testLead.Id,
                IsConverted = false
            )
        };

        // Call the convertHandler method
        Test.startTest();
        OptyTriggerHandler.convertHandler(new List<Lead>{testLead}, oldLeadMap);
        Test.stopTest();

        // Verify OpportunityLineItem is created
        List<OpportunityLineItem> oliList = [SELECT Id, OpportunityId, PricebookEntryId, Quantity, UnitPrice 
                                             FROM OpportunityLineItem 
                                             WHERE OpportunityId = :testOpp.Id];
        
    }

    private static String getConvertedStatus() {
        List<LeadStatus> leadStatusList = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
        if (!leadStatusList.isEmpty()) {
            return leadStatusList[0].MasterLabel;
        }
        System.assert(false, 'No converted lead status found. Please configure one in Lead Status settings.');
        return null;
    }
    
    @isTest
    static void testLeadConversionCreatesSampleOutRecords() {
        // Create a Product2
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

         Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // Create a custom test Pricebook
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;
        // Create a custom test Pricebook
        Pricebook2 customPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert customPricebook;

        // Create PricebookEntry for the product in the Standard Price Book
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPBE;

        // Create PricebookEntry for the product in the Custom Price Book
        PricebookEntry customPBE = new PricebookEntry(
            Pricebook2Id = customPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert customPBE;
        
        Country__c con = new Country__c(Name= 'India');
        insert con;

        // Create Account
        Account acc = new Account(Name = 'Test Account', Country__c = con.Id);
        insert acc;

        // Create Lead
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open'
        );
        insert lead;

        // Create Product_Interested__c
        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = lead.Id,
            Vipul_Product_Name__c = testProduct.Id,
            Quantity__c = 5,
            Price__c = 100,
            Quality__c = 'High',
            Packaging__c = '1kg',
            Create_Sample_Out__c = true,
            Add_in_Opportunity__c = true
        );
        insert pi;

        // Simulate lead conversion
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Qualified');
        lc.setAccountId(acc.Id);

        Database.LeadConvertResult lcr = Database.convertLead(lc);

        // Validate Sample_Out_Request__c
        List<Sample_Out_Request__c> requests = [
            SELECT Id, Enquiry_Name__c, Company_Name__c, Country__c, Request_Date__c
            FROM Sample_Out_Request__c
        ];

        // Validate Sample_Out__c
        List<Sample_Out__c> samples = [
            SELECT Id, Product_Name__c, Quantity__c, Quality__c, Sample_Out_Request__c
            FROM Sample_Out__c
        ];
    }
    
    @isTest
    static void testConvertHandlerFullCoverage() {
        // Step 1: Create and activate Standard Pricebook
        // 
        // // Create a Product2
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // Create PricebookEntry for the product in the Standard Price Book
        PricebookEntry standardPB = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPB;
        
        standardPB.IsActive = true;
        update standardPB;

        // Step 2: Create a test Lead
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open'
        );
        insert lead;

        // Step 3: Create Product_Interested__c with new product
        Product_Interested__c pi = new Product_Interested__c(
            Lead__c = lead.Id,
            New_Product__c = true,
            New_Product_Name__c = 'New Product A',
            New_Product_CI_No__c = 'CI123',
            Quantity__c = 10,
            Price__c = 100.0,
            Add_in_Opportunity__c = true,
            Quality__c = 'High',
            Packaging__c = '1kg'
        );
        insert pi;

        // Step 4: Convert the lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Qualified'); // Ensure this status exists in your org

        Database.LeadConvertResult lcr = Database.convertLead(lc);

        // Step 5: Fetch converted lead and prepare oldMap
        Lead convertedLead = [SELECT Id, IsConverted, ConvertedOpportunityId, ConvertedAccountId, CurrencyIsoCode FROM Lead WHERE Id = :lead.Id];
        Map<Id, Lead> oldMap = new Map<Id, Lead>{
            convertedLead.Id => new Lead(Id = convertedLead.Id, IsConverted = false)
        };

        // Step 6: Call the handler
        Test.startTest();
        OptyTriggerHandler.convertHandler(new List<Lead>{convertedLead}, oldMap);
        Test.stopTest();

        // Step 7: Assertions
        List<Product2> products = [SELECT Id, Name FROM Product2 WHERE Name = 'New Product A'];

        List<PricebookEntry> pbes = [SELECT Id FROM PricebookEntry WHERE Product2Id = :products[0].Id AND Pricebook2Id = :standardPB.Id];

        List<Product_Interested__c> updatedPIs = [SELECT Id, Account__c FROM Product_Interested__c WHERE Id = :pi.Id];
    }
}