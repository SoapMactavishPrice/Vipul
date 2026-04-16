@isTest
private class SampleOutMailControllerTest {

    @testSetup
    static void setupTestData() {
        // Create test Account with Email_ID__c
        Account acc = new Account(Name = 'Test Company', Email_ID__c = 'company@example.com');
        insert acc;

        // Create test Contact (Person__c)
        Contact person1 = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com');
        insert person1;
        
        Country__c testCountry = new Country__c(Name = 'Test Country');
        insert testCountry;
        
        State__c testState = new State__c(Name = 'Test State', Country__c = testCountry.Id);
        insert testState;
        
        City__c testCity = new City__c(Name = 'Test City', State__c = testState.Id);
        insert testCity;
        
        Area__c testArea = new Area__c(Name = 'Test Area', City__c = testCity.Id);
        insert testArea;
        
        Pin_Code__c testPostalCode = new Pin_Code__c(Name = '12345', Area__c = testArea.Id);
        insert testPostalCode;
        
        // Create a test Opportunity (Enquiry)
        Opportunity enquiry = new Opportunity(
            Name = 'ENQ001',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert enquiry;
        

       // Create test user
        Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User person = new User(
            ProfileId = stdProfile.Id,
            LastName = 'TestUser',
            Email = 'testuser@example.com',
            Username = 'testusegfbgjmgffr@example.com' + System.currentTimeMillis(),
            CompanyName = 'Test Company',
            Title = 'Test Title',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            User_Division__c = 'Domestic'
        );
        insert person;
        
        // Then assign the person.Id correctly
        Sample_Out_Request__c request = new Sample_Out_Request__c(
            Request_Date__c = Date.today(),
            Received_Date__c = Date.today().addDays(2),
            Country__c = testCountry.Id,
            Company_Name__c = acc.Id,
            Person__c = person.Id, // this is a User ID
            Enquiry_Name__c = enquiry.Id
        );
        insert request;

        // Create Sample_Out__c records
        List<Sample_Out__c> outList = new List<Sample_Out__c>();
        for (Integer i = 1; i <= 2; i++) {
            Sample_Out__c sample = new Sample_Out__c(
               // Name = 'Sample ' + i,
                Sample_Sent_to_Unit__c = null,
                Application__c = 'App ' + i,
                Product_Name__c = null,
                Colour_Index_Name__c = 'Color ' + i,
                Quality__c = 'Q' + i,
                Quantity__c = 100 * i,
                Sample_Out_Request__c = request.Id,
               // Packets__c = i,
                Unit_of_Measure__c = 'Kilogram (Kg)',
                Reference_Number__c = 'REF' + i,
                Tracking_Number__c = 'TRACK' + i,
                New_Product_Name__c = 'New Product ' + i
            );
            outList.add(sample);
        }
        insert outList;
    }

    @isTest
    static void testConstructorAndEmail() {
        // Fetch inserted Sample_Out_Request__c
        Sample_Out_Request__c req = [SELECT Id FROM Sample_Out_Request__c LIMIT 1];

        Test.setCurrentPageReference(new PageReference('/apex/SampleOutMailPage'));
        ApexPages.currentPage().getParameters().put('id', req.Id);

        SampleOutMailController controller = new SampleOutMailController();

       
    }

    @isTest
    static void testSaveAndSend() {
        Sample_Out_Request__c req = [SELECT Id FROM Sample_Out_Request__c LIMIT 1];
        Test.setCurrentPageReference(new PageReference('/apex/SampleOutMailPage'));
        ApexPages.currentPage().getParameters().put('id', req.Id);

        SampleOutMailController controller = new SampleOutMailController();
        controller.emailId = 'recipient@example.com';
        controller.subject = 'Test Subject';
        controller.CC_Addresses = 'cc1@example.com, cc2@example.com';

        Test.startTest();
        PageReference result = controller.saveAndSend();
        Test.stopTest();

       
    }

    @isTest
    static void testSaveAndSend_MissingEmail() {
        Sample_Out_Request__c req = [SELECT Id FROM Sample_Out_Request__c LIMIT 1];
        Test.setCurrentPageReference(new PageReference('/apex/SampleOutMailPage'));
        ApexPages.currentPage().getParameters().put('id', req.Id);

        SampleOutMailController controller = new SampleOutMailController();
        controller.emailId = '';  // Missing email
        controller.subject = 'Subject';

        Test.startTest();
        PageReference result = controller.saveAndSend();
        Test.stopTest();

      
    }

    @isTest
    static void testCancel() {
        Sample_Out_Request__c req = [SELECT Id FROM Sample_Out_Request__c LIMIT 1];
        Test.setCurrentPageReference(new PageReference('/apex/SampleOutMailPage'));
        ApexPages.currentPage().getParameters().put('id', req.Id);

        SampleOutMailController controller = new SampleOutMailController();
        PageReference result = controller.cancel();

      
    }
}