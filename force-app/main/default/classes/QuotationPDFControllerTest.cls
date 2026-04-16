@isTest
private class QuotationPDFControllerTest {

    @TestSetup
    static void setupTestData() {
        
        Country__c testCountry = new Country__c(Name = 'India');
        insert testCountry;
        
        State__c testState = new State__c(Name = 'Test State', Country__c = testCountry.Id);
        insert testState;
        
        City__c testCity = new City__c(Name = 'Test City', State__c = testState.Id);
        insert testCity;
        
        Area__c testArea = new Area__c(Name = 'Test Area', City__c = testCity.Id);
        insert testArea;
        
        Pin_Code__c testPostalCode = new Pin_Code__c(Name = '12345', Area__c = testArea.Id);
        insert testPostalCode;
        
        // Get the standard Pricebook using the Test method
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // Ensure the standard pricebook is active
        standardPricebook.IsActive = true;
        update standardPricebook;
        
        // Create a custom test Pricebook
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;
        
        // Create an Account
        Account testAccount = new Account(
            Name = 'Test Account', 
            CurrencyIsoCode = 'USD',
            Country__c= testCountry.id,
            City__c=testCity.id,
            State__c=testState.id,
            Area__c=testArea.id,
            Street__c='MBP Road',
            Pin_Code__c=testPostalCode.id,
            INCO_Terms__c = 'DDP'
        );
        insert testAccount;
        
        // FIX: Added CurrencyIsoCode to match Account's currency
        Address_Information__c add = new Address_Information__c(
            Country__c= testCountry.id,
            City__c=testCity.id,
            State__c=testState.id,
            Area__c=testArea.id,
            Street__c='MBP Road',
            Pin_Code__c=testPostalCode.id,
        	Account__c = testAccount.Id,
            CurrencyIsoCode = 'USD'  // Added this line to fix the error
        );
        insert add;
        
        Contact con = new Contact();
        con.AccountId = testAccount.id;
        con.FirstName = 'Prashant';
        con.LastName = 'Padal';
        con.Email = 'Prashantpadal@finessedirect.com';
        con.Phone = '123-456-7890';
        con.CurrencyIsoCode = 'USD';
        con.Country__c= testCountry.id;
        con.City__c=testCity.id;
        con.State__c=testState.id;
        con.Area__c=testArea.id;
        con.Street__c='MBP Road';
        con.Pin_Code__c=testPostalCode.id; 
        insert con;
        
        // Create an Opportunity (since Quote requires an OpportunityId)
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            AccountId = testAccount.Id
        );
        insert opp;
        
        // Create a Product
        Product2 prod = new Product2(
            Name = 'Test Product', 
            Family = 'Test Family', 
            IsActive = true
        );
        insert prod;
        
        // **Create a PricebookEntry for the standard pricebook (required)**
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true
           // UseStandardPrice = true // Use the standard pricebook
        );
        insert standardPbe;
        
        // **Now, create a custom price book entry**
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true, 
            UseStandardPrice = false // Use custom pricebook
        );
        insert customPbe;
        
        // Create a Quote with the required OpportunityId
        Quote quote = new Quote(
            Name = 'Test Quote', 
            OpportunityId = opp.Id,  // Required field!
            Pricebook2Id = testPricebook.Id, 
            CurrencyIsoCode = 'USD',
            ContactId = con.id,
            Consignee_Address1__c = add.id,
            Delivery_Address1__c = add.Id
        );
        insert quote;
        
        // Create a QuoteLineItem (Required for the Quote to be valid)
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = customPbe.Id,
            Quantity = 10,
            UnitPrice = 100
        );
        insert qli;
        
        // Create a User (for the test runAs)
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'testuser',
            Email = 'Sahil@finessedirect.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserName = 'testuserr45678@example.com',
            TimeZoneSidKey = 'America/New_York', // Added required field
            LocaleSidKey = 'en_US'               // Added required field
        );
        insert testUser;

        System.runAs(testUser) {
            // Create other test data here if necessary
        }
    }
    
    @isTest
    static void testControllerMethods() {
        // Query for a Quote for the test
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        // Start the test
        Test.startTest();
        
        // Set up the page reference for the PDF generation
        PageReference pageRef = Page.QuotePDF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testQuote.Id);
        
        // Instantiate the controller
        QuotationPDFController controller = new QuotationPDFController();
        
        // Call the methods to be tested
        controller.save();
        controller.saveAndSend();
        controller.cancel();
        
        Test.stopTest();
    }
}