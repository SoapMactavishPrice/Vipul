@isTest
public class CasePDFControllerTest {
    
    @isTest
    static void testCasePDFControllerWithId() {
        // Create test data
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Phone',
            Reason = 'Installation',
            Corrective_Description__c = 'Corrective action',
            Date_Implemented__c = Date.today().addDays(-5),
            Date_Completed__c = Date.today().addDays(-3),
            Date_Implemented_Prevent__c = Date.today().addDays(-2),
            Date_Completed_Prevent__c = Date.today().addDays(-1)
        );
        insert testCase;

        // Set the page parameters
        Test.setCurrentPage(Page.CasePDFForm); // Replace with your actual VF page name
        ApexPages.currentPage().getParameters().put('id', testCase.Id);

        // Instantiate the controller
        CasePDFController controller = new CasePDFController();

    }

    @isTest
    static void testCasePDFControllerWithoutId() {
        // No ID in parameters
        Test.setCurrentPage(Page.CasePDFForm); // Replace with your actual VF page name

        // Instantiate the controller
        //CasePDFController controller = new CasePDFController();

    }
}