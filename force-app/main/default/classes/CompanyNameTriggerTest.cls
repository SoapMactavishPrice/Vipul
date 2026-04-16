@isTest
public class CompanyNameTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Insert test data if needed before tests run
    }
    
    @isTest
    static void testBeforeInsertTrigger() {
        // Create a test record
        Company_Name__c testCompany = new Company_Name__c(Name = 'Test Company');
        
        // Insert the record to fire the trigger
        Test.startTest();
        insert testCompany;
        Test.stopTest();
        
        // Retrieve the inserted record
        Company_Name__c insertedCompany = [SELECT Id, Name FROM Company_Name__c WHERE Id = :testCompany.Id LIMIT 1];
        
        // Add assertions (modify as per your handler logic)
        System.assertNotEquals(null, insertedCompany, 'Company record should be inserted.');
    }

    @isTest
    static void testBeforeUpdateTrigger() {
        // Create and insert a test record
        Company_Name__c testCompany = new Company_Name__c(Name = 'Test Company');
        insert testCompany;
        
        // Update the record
        testCompany.Name = 'Updated Company';
        
        Test.startTest();
        update testCompany;
        Test.stopTest();
        
        // Retrieve the updated record
        Company_Name__c updatedCompany = [SELECT Id, Name FROM Company_Name__c WHERE Id = :testCompany.Id LIMIT 1];
        
        // Add assertions (modify as per your handler logic)
        System.assertEquals('Updated Company', updatedCompany.Name, 'Company name should be updated.');
    }
}