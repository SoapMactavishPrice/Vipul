@isTest
public class SampleInOutMailControllerTest {

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account', Email_ID__c = 'testaccount@example.com');
        insert acc;

        Contact person = new Contact(LastName = 'Test Contact', Email = 'testcontact@example.com');
        insert person;
        
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
        
         Id PID = Test.getStandardPricebookId();
        
         Product2 prod = new Product2();
        prod.name='Product A';
        prod.isActive=true;
        insert prod;
        
         Unit_Master__c unit = new Unit_Master__c(Name = 'Test Unit');
        insert unit;
        
         Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User testUser = new User(
            Alias = 'testusr',
            Email = 'testuserv8779879889@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuserda23247887tvt@example.com'
        );
        insert testUser;
        
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Finesse';
        opp.StageName = 'Sampling';
        opp.CloseDate = Date.today();
        opp.AccountId = acc.Id;
        opp.Contact__c = person.Id;
        opp.Pricebook2Id=PID;
        
        insert opp;

        Sample_In_Request__c request = new Sample_In_Request__c(
            //Name = 'REQ001',
            Person__c = testUser.Id,
            Received_Date__c = Date.today(),
            Country__c = testCountry.Id ,
            Company_Name__c = acc.Id,
            OwnerId = UserInfo.getUserId(),
            Enquiry_Name__c = opp.Id
        );
        insert request;

        Sample_In__c sampleIn = new Sample_In__c(
            Sample_Sent_to_Unit__c = unit.Id,
            VOL_Product_Name__c =prod.Id,
            Courier_Tracking_No__c = 'TRK12345',
            Sample_Out_Ref_No__c = 'OUT12345',
            Sample_In_Request__c = request.Id,
            Quantity__c = 100
        );
        insert sampleIn;
    }

    @isTest
    static void testConstructor() {
        Test.setCurrentPage(Page.SampleRequestMailInOutTemplate);
        Id requestId = [SELECT Id FROM Sample_In_Request__c LIMIT 1].Id;
        ApexPages.currentPage().getParameters().put('id', requestId);
        
        SampleInOutMailController controller = new SampleInOutMailController();
       
    }

    @isTest
    static void testSaveAndSend_Success() {
        Test.setCurrentPage(Page.SampleRequestMailInOutTemplate);
        Id requestId = [SELECT Id FROM Sample_In_Request__c LIMIT 1].Id;
        ApexPages.currentPage().getParameters().put('id', requestId);

        SampleInOutMailController controller = new SampleInOutMailController();
        controller.subject = 'Test Subject';
        controller.emailId = 'recipient@example.com';
        controller.CC_Addresses = 'cc1@example.com;cc2@example.com';

        Test.startTest();
        PageReference result = controller.saveAndSend();
        Test.stopTest();

        
    }

    @isTest
    static void testSaveAndSend_Error() {
        Test.setCurrentPage(Page.SampleRequestMailInOutTemplate);
        Id requestId = [SELECT Id FROM Sample_In_Request__c LIMIT 1].Id;
        ApexPages.currentPage().getParameters().put('id', requestId);

        SampleInOutMailController controller = new SampleInOutMailController();
        controller.subject = '';
        controller.emailId = ''; 

        Test.startTest();
        PageReference result = controller.saveAndSend();
        Test.stopTest();

    }

    @isTest
    static void testCancel() {
        Test.setCurrentPage(Page.SampleRequestMailInOutTemplate);
        Id requestId = [SELECT Id FROM Sample_In_Request__c LIMIT 1].Id;
        ApexPages.currentPage().getParameters().put('id', requestId);

        SampleInOutMailController controller = new SampleInOutMailController();

        PageReference cancelPage = controller.cancel();
    }
}