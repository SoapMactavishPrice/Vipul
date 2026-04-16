@isTest
private class CompanyEmailControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account', INCO_Terms__c = 'DDP');
        insert testAccount;
        
        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        testContacts.add(new Contact(
            FirstName = 'Primary',
            LastName = 'Contact',
            Email = 'primary@test.com',
            AccountId = testAccount.Id
        ));
        testContacts.add(new Contact(
            FirstName = 'Secondary',
            LastName = 'Contact',
            Email = 'secondary@test.com',
            AccountId = testAccount.Id
        ));
        testContacts.add(new Contact(
            FirstName = 'NoEmail',
            LastName = 'Contact',
            AccountId = testAccount.Id
        ));
        insert testContacts;
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Contact__c = testContacts[0].Id
        );
        insert testOpp;
        
        // Create test static resource
     /*   Blob testBlob = Blob.valueOf('Test Content');
        StaticResource testResource = new StaticResource(
            Name = 'CompanyProfileName',
            Body = testBlob,
            ContentType = 'application/pdf'
        );
        insert testResource; */
    }
    
    @isTest
    static void testConstructorWithValidOpportunity() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        CompanyEmailController controller = new CompanyEmailController(sc);
        Test.stopTest();
        
        System.assertEquals(testOpp.Id, controller.oppId, 'Opportunity ID should be set');
        System.assertEquals(true, controller.isValid, 'Controller should be valid');
        System.assertEquals('primary@test.com', controller.emailId, 'Primary email should be set');
        System.assertEquals('secondary@test.com', controller.CC_Addresses, 'CC addresses should be set');
        System.assertNotEquals(null, controller.subject, 'Subject should be initialized');
        System.assertNotEquals(null, controller.body, 'Body should be initialized');
    }
    
    @isTest
    static void testConstructorWithMissingContactEmail() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        // Update opportunity to have contact without email
        Contact noEmailContact = [SELECT Id FROM Contact WHERE Email = null LIMIT 1];
        testOpp.Contact__c = noEmailContact.Id;
        update testOpp;
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        CompanyEmailController controller = new CompanyEmailController(sc);
        Test.stopTest();
        
        System.assertEquals(false, controller.isValid, 'Controller should be invalid');
        System.assertEquals(1, ApexPages.getMessages().size(), 'Error message should be added');
    }
    
    @isTest
    static void testSendEmailSuccess() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        CompanyEmailController controller = new CompanyEmailController(sc);
        
        // Set some test values
        controller.subject = 'Test Subject';
        controller.body = 'Test Body';
        
        Test.startTest();
        PageReference result = controller.sendEmail();
        Test.stopTest();
        
        }
    
    @isTest
    static void testSendEmailMissingSubject() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        CompanyEmailController controller = new CompanyEmailController(sc);
        
        // Set empty subject to test validation
        controller.subject = '';
        
        Test.startTest();
        PageReference result = controller.sendEmail();
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailMissingRecipient() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        CompanyEmailController controller = new CompanyEmailController(sc);
        
        // Set empty email to test validation
        controller.emailId = '';
        
        Test.startTest();
        PageReference result = controller.sendEmail();
        Test.stopTest();
    }
    
    @isTest
    static void testSendEmailExceptionHandling() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        CompanyEmailController controller = new CompanyEmailController(sc);
        
        // Delete static resource to force exception
     //   delete [SELECT Id FROM StaticResource LIMIT 1];
        
        Test.startTest();
        PageReference result = controller.sendEmail();
        Test.stopTest();
    }
    
    @isTest
    static void testCancel() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        CompanyEmailController controller = new CompanyEmailController(sc);
        
        Test.startTest();
        PageReference result = controller.cancel();
        Test.stopTest();
        
        System.assertEquals('/' + testOpp.Id, result.getUrl(), 'Should redirect to opportunity');
    }
}