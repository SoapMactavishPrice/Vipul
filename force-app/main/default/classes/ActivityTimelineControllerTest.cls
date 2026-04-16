@isTest
private class ActivityTimelineControllerTest {
    @testSetup
    static void setupTestData() {
        // Create a test user with an allowed currency setting
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'testuser',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create a test Contact record with a valid CurrencyIsoCode
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            OwnerId = testUser.Id, // Assign to the created user
            CurrencyIsoCode = 'USD' // Change to a valid currency
        );
        insert testContact;

        // Create test Task records associated with the Contact
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 5; i++) {
            tasks.add(new Task(
                Subject = 'Test Task ' + i,
                Status = 'Not Started',
                Priority = 'Normal',
                ActivityDate = Date.today().addDays(-i),
                WhoId = testContact.Id
            ));
        }
        insert tasks;
    }

    @isTest
    static void testGetRecentActivities() {
        // Retrieve the test Contact
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        // Call the method being tested
        Test.startTest();
        List<Task> recentActivities = ActivityTimelineController.getRecentActivities(testContact.Id);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(0, recentActivities.size(), 'Activities should be retrieved');
        System.assertEquals(5, recentActivities.size(), 'Expected number of tasks should match');
        System.assert(recentActivities[0].ActivityDate >= recentActivities[recentActivities.size()-1].ActivityDate, 'Tasks should be ordered by ActivityDate DESC');
    }
}