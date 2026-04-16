@isTest
public class CompanyBankTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Company_Name__c record
        Company_Name__c companyInfo = new Company_Name__c(
            Name = 'Test Company'
        );
        insert companyInfo;

        // Create test records for Company_Bank__c with the required field
        Company_Bank__c bank = new Company_Bank__c(
            Name = 'Test Bank',
            Bank_Address__c = '123 Test Street',
            Bank_Name__c = companyInfo.Id, // Assuming this is a correct lookup
            Company_Information__c = companyInfo.Id // Ensure required field is set
        );
        insert bank;
    }

    @isTest
    static void testBeforeInsert() {
        // Fetch the existing Company_Name__c record
        Company_Name__c companyInfo = [SELECT Id FROM Company_Name__c LIMIT 1];

        // Create a new Company_Bank__c record with the required field
        Company_Bank__c newBank = new Company_Bank__c(
            Name = 'New Test Bank',
            Bank_Address__c = '456 New Street',
            Bank_Name__c = companyInfo.Id, // Assuming this is a lookup
            Company_Information__c = companyInfo.Id // Ensure required field is set
        );

        Test.startTest();
        insert newBank;
        Test.stopTest();

        // Verify that the trigger executed successfully
        Company_Bank__c insertedBank = [SELECT Id, Bank_Address__c FROM Company_Bank__c WHERE Id = :newBank.Id];
        System.assertNotEquals(null, insertedBank.Bank_Address__c, 'Address should be populated.');
    }

    @isTest
    static void testBeforeUpdate() {
        // Fetch an existing Company_Bank__c record
        Company_Bank__c existingBank = [SELECT Id, Bank_Address__c FROM Company_Bank__c LIMIT 1];

        // Update Address
        existingBank.Bank_Address__c = '789 Updated Street';

        Test.startTest();
        update existingBank;
        Test.stopTest();

        // Verify that the trigger executed successfully
        Company_Bank__c updatedBank = [SELECT Id, Bank_Address__c FROM Company_Bank__c WHERE Id = :existingBank.Id];
        System.assertEquals('789 Updated Street', updatedBank.Bank_Address__c, 'Address should be updated.');
    }
}