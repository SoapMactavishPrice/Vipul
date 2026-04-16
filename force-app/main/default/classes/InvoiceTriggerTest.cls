@isTest
public class InvoiceTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Insert any required test data before running tests
    }
    
    @isTest
    static void testAfterInsertTrigger() {
        // Create a test invoice record
        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice');

        // Insert the invoice to trigger 'after insert' logic
        Test.startTest();
        insert testInvoice;
        Test.stopTest();

        // Retrieve the inserted record (if needed for further validation)
        Invoice__c insertedInvoice = [SELECT Id, Name FROM Invoice__c WHERE Id = :testInvoice.Id LIMIT 1];

    }
}