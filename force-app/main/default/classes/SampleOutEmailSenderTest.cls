@isTest
private class SampleOutEmailSenderTest {

    @isTest
    static void testSendEmailAsync() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Create Unit_Master__c
        Unit_Master__c unit1 = new Unit_Master__c(
            Name = 'Unit 1',
            Email_1__c = 'unit1@example.com',
            Email_2__c = 'unit1_2@example.com',
            Email_3__c = 'unit1_3@example.com'
        );
        insert unit1;

        // Create Product2 record (used for Product_Name__r reference)
        Product2 product = new Product2(
            Name = 'Test Product',
            CI_no__c = 'CI123'
        );
        insert product;

        // Create Sample_Out_Request__c
        Sample_Out_Request__c request = new Sample_Out_Request__c(
           // Name = 'Sample Out Request 001',
            Person__c = testUser.Id,
            Request_Date__c = Date.today(),
            Sample_Request_Status__c = 'Sample Sent to HO'
        );
        insert request;

        // Create Sample_Out__c record
        Sample_Out__c sampleOut = new Sample_Out__c(
           // Name = 'Sample Out 001',
            Sample_Out_Request__c = request.Id,
            Sample_Sent_to_Unit__c = unit1.Id,
            Product_Name__c = product.Id,
            Application__c = 'Test Application',
            Quality__c = 'High',
            Quantity__c = 10,
          //  Packets__c = 2,
            Unit_of_Measure__c = 'Kilogram (Kg)',
            Sample_Out_Status__c = 'Sample Sent to HO'
        );
        insert sampleOut;

        // Call the future method within Test context
        Test.startTest();
        SampleOutEmailSender.sendEmailAsync(request.Id);
        SampleOutEmailSender.sendHOEmailAsync(request.id);
        Test.stopTest();

        // Optional: System.asserts can be added here to verify post-execution logic like querying tasks, logs, etc.
        System.debug('Test completed successfully.');
    }
}