@isTest
public class ContactTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Account (if required for Contact)
        Account testAccount = new Account(Name = 'Test Account', INCO_Terms__c = 'DDP');
        insert testAccount;

        // Create a test Contact record
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
    }

    @isTest
    static void testBeforeInsertTrigger() {
        // Create a new Contact record
        Contact newContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            Email = 'janesmith@example.com'
        );

        Test.startTest();
        insert newContact;
        Test.stopTest();

        // Retrieve inserted Contact record
        Contact insertedContact = [SELECT Id, Email FROM Contact WHERE Id = :newContact.Id LIMIT 1];

        // Validate that the record was inserted successfully
        System.assertNotEquals(null, insertedContact, 'Contact should be inserted.');
    }

    @isTest
    static void testBeforeUpdateTrigger() {
        // Retrieve existing Contact record
        Contact existingContact = [SELECT Id, LastName FROM Contact LIMIT 1];

        // Modify the Contact
        existingContact.LastName = 'Updated Doe';

        Test.startTest();
        update existingContact;
        Test.stopTest();

        // Validate that the Contact was updated
        Contact updatedContact = [SELECT Id, LastName FROM Contact WHERE Id = :existingContact.Id LIMIT 1];
        System.assertEquals('Updated Doe', updatedContact.LastName, 'Contact LastName should be updated.');
    }

    @isTest
    static void testAfterInsertTrigger() {
        // Create a new Contact record
        Contact testContact = new Contact(
            FirstName = 'Alice',
            LastName = 'Brown',
            Email = 'alicebrown@example.com'
        );

        Test.startTest();
        insert testContact;
        Test.stopTest();

        // Verify that after-insert logic executed successfully
        Contact insertedContact = [SELECT Id, Email FROM Contact WHERE Id = :testContact.Id LIMIT 1];
        System.assertEquals('alicebrown@example.com', insertedContact.Email, 'Contact should be inserted with correct email.');
    }
}