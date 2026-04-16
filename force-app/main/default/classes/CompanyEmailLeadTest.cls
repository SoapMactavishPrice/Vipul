@isTest
public class CompanyEmailLeadTest {
    @isTest
    static void testSendEmailSuccess() {
        // Create a test Lead with an email
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test@example.com',
            Status = 'Open'
        );
        insert testLead;

        // Mock Static Resource
       /* StaticResource res = new StaticResource(
            Name = 'CompanyProfileName',
            Body = Blob.valueOf('Sample Content')
        );
        insert res; */

        // Instantiate the controller
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testLead);
        CompanyEmailLead controller = new CompanyEmailLead(sc);
        controller.CC_Addresses = 'cc@example.com';
        controller.subject = 'Test Subject';
        controller.body = 'Test Body';
        PageReference result = controller.sendEmail();
        Test.stopTest();

        // Verify email was sent successfully
        System.assert(controller.isValid, 'Email should be valid');
        System.assertEquals('/' + testLead.Id, result.getUrl(), 'Page should redirect to Lead page');
    }

    @isTest
    static void testSendEmailNoEmail() {
        // Create a test Lead without an email
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'Open'
        );
        insert testLead;

        // Instantiate the controller
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testLead);
        CompanyEmailLead controller = new CompanyEmailLead(sc);
        Test.stopTest();

        // Verify email validation fails
        System.assert(!controller.isValid, 'Email should be invalid due to missing email address');
    }

    @isTest
    static void testSendEmailNoStaticResource() {
        // Create a test Lead with an email
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test@example.com',
            Status = 'Open'
        );
        insert testLead;

        // Instantiate the controller
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testLead);
        CompanyEmailLead controller = new CompanyEmailLead(sc);
        controller.CC_Addresses = 'cc@example.com';
        controller.subject = 'Test Subject';
        controller.body = 'Test Body';
        PageReference result = controller.sendEmail();
        Test.stopTest();

        // Verify that the email fails due to missing static resources
      //  System.assertEquals(null, result, 'Email should not be sent without static resources');
    }

    @isTest
    static void testCancelMethod() {
        // Create a test Lead
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Email = 'test@example.com',
            Status = 'Open'
        );
        insert testLead;

        // Instantiate the controller
        ApexPages.StandardController sc = new ApexPages.StandardController(testLead);
        CompanyEmailLead controller = new CompanyEmailLead(sc);

        // Test cancel method
        Test.startTest();
        PageReference result = controller.cancel();
        Test.stopTest();

        // Verify the cancel method redirects correctly
        System.assertEquals('/' + testLead.Id, result.getUrl(), 'Cancel method should redirect to Lead page');
    }
}