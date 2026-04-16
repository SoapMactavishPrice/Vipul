@isTest
public class ContactInformationTriggerTest {
    
    @isTest
    static void testBeforeInsertTrigger() {
        Test.startTest();
        
        // Create a test Contact Information record
        Contact_Information__c testContactInfo = new Contact_Information__c(
            Name = 'Test Contact Info'
            // Add other required fields here if necessary
        );

        insert testContactInfo;

        Test.stopTest();

        // Retrieve inserted Contact_Information__c record
        Contact_Information__c insertedContactInfo = [SELECT Id, Name FROM Contact_Information__c WHERE Id = :testContactInfo.Id LIMIT 1];

        // Validate that the record was inserted successfully
        System.assertNotEquals(null, insertedContactInfo, 'Contact_Information__c record should be inserted.');
    }
}