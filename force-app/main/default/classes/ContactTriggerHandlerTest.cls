@IsTest
public class ContactTriggerHandlerTest {
    
    @isTest
    static void testUpdateContactAddresses() {

        // Create a test user
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
            UserName = 'testuserda2324@example.com'
        );
        insert testUser;

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

        // Creating contacts with explicit CurrencyIsoCode and OwnerId
        Contact contactWithPostalCode = new Contact(
            LastName = 'Contact with Postal Code',
            Pin_Code__c = testPostalCode.Id,
            CurrencyIsoCode = 'USD', // Set an allowed currency
            OwnerId = testUser.Id    // Assign the created test user
        );

        Contact contactWithArea = new Contact(
            LastName = 'Contact with Area',
            Area__c = testArea.Id,
            CurrencyIsoCode = 'USD',
            OwnerId = testUser.Id
        );

        Contact contactWithCity = new Contact(
            LastName = 'Contact with City',
            City__c = testCity.Id,
            CurrencyIsoCode = 'USD',
            OwnerId = testUser.Id
        );

        Contact contactWithState = new Contact(
            LastName = 'Contact with State',
            State__c = testState.Id,
            CurrencyIsoCode = 'USD',
            OwnerId = testUser.Id
        );

        insert new List<Contact> { contactWithPostalCode, contactWithArea, contactWithCity, contactWithState };

        List<Contact> contacts = [SELECT Id, LastName, Pin_Code__c, Area__c, City__c, State__c, Country__c FROM Contact];
        
        Test.startTest();
        ContactTriggerHandler.updateContactAddresses(contacts);
        Test.stopTest();

        for (Contact contact : contacts) {
            if (contact.LastName == 'Contact with Postal Code') {
                System.assertEquals(testArea.Id, contact.Area__c, 'Area__c not updated correctly.');
                System.assertEquals(testCity.Id, contact.City__c, 'City__c not updated correctly.');
                System.assertEquals(testState.Id, contact.State__c, 'State__c not updated correctly.');
                System.assertEquals(testCountry.Id, contact.Country__c, 'Country__c not updated correctly.');
            } else if (contact.LastName == 'Contact with Area') {
                System.assertEquals(testCity.Id, contact.City__c, 'City__c not updated correctly.');
                System.assertEquals(testState.Id, contact.State__c, 'State__c not updated correctly.');
                System.assertEquals(testCountry.Id, contact.Country__c, 'Country__c not updated correctly.');
            } else if (contact.LastName == 'Contact with City') {
                System.assertEquals(testState.Id, contact.State__c, 'State__c not updated correctly.');
                System.assertEquals(testCountry.Id, contact.Country__c, 'Country__c not updated correctly.');
            } else if (contact.LastName == 'Contact with State') {
                System.assertEquals(testCountry.Id, contact.Country__c, 'Country__c not updated correctly.');
            }
        }
    }
    
    @isTest
    static void testHandleAfterInsert() {
        // Create an Account with empty custom fields
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create a Contact related to the Account
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            MobilePhone = '1234567890',
            AccountId = acc.Id
        );
        insert con;

        // Call the method under test
        Test.startTest();
        ContactTriggerHandler.handleAfterInsert(new List<Contact>{con});
        Test.stopTest();

        // Retrieve the updated Account
        Account updatedAcc = [SELECT Contact__c, Contact_Name__c, Contact_s_Email__c, Contact_s_Mobile__c 
                              FROM Account WHERE Id = :acc.Id];

    }

    @isTest
    static void testHandleAfterInsert_FirstNameBlank() {
        // Create an Account with empty custom fields
        Account acc = new Account(Name = 'Test Account 2');
        insert acc;

        // Create a Contact with blank FirstName
        Contact con = new Contact(
            LastName = 'Smith',
            Email = 'smith@example.com',
            MobilePhone = '9876543210',
            AccountId = acc.Id
        );
        insert con;

        // Call the method under test
        Test.startTest();
        ContactTriggerHandler.handleAfterInsert(new List<Contact>{con});
        Test.stopTest();

        // Retrieve the updated Account
        Account updatedAcc = [SELECT Contact_Name__c FROM Account WHERE Id = :acc.Id];

    }
}