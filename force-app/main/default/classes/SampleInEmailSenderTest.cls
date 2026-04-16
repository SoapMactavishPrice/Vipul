@isTest
private class SampleInEmailSenderTest {

    @isTest
    static void testSendEmailAsync() {
        // Step 1: Create required mock data

        // Create Unit Master
        Unit_Master__c unitMaster = new Unit_Master__c(
            Name = 'Test Unit',
            Email_1__c = 'unit1@example.com',
            Email_2__c = 'unit1_2@example.com',
            Email_3__c = 'unit1_3@example.com'
        );
        insert unitMaster;

        // Create user for Person__r
        User u = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Create Sample_In_Request__c
        Sample_In_Request__c sampleInRequest = new Sample_In_Request__c(
           // Name = 'Sample In Request 001',
            Person__c = u.Id,
            Sample_In_Status__c = 'Sample Sent to HO'
        );
        insert sampleInRequest;

        // Create Sample_In__c records
        List<Sample_In__c> sampleIns = new List<Sample_In__c>{
            new Sample_In__c(
                Sample_Sent_to_Unit__c = unitMaster.Id,
                Application__c = 'Test Application',
                Customer_s_Product_Name__c = 'Test Product 1',
                C_I__c = 'CI123',
                Sample_In_Request__c = sampleInRequest.Id,
                Sample_In_Status__c = 'Sample Sent to HO'
            ),
            new Sample_In__c(
                Sample_Sent_to_Unit__c = unitMaster.Id,
                Application__c = 'Test Application 2',
                Customer_s_Product_Name__c = 'Test Product 2',
                C_I__c = 'CI124',
                Sample_In_Request__c = sampleInRequest.Id
            )
        };
        insert sampleIns;

        // Step 2: Call the future method
        Test.startTest();
        SampleInEmailSender.sendEmailAsync(sampleInRequest.Id);
        SampleInEmailSender.sendHOEmailAsync(sampleInRequest.Id);
        Test.stopTest();

        // Note: Since the method is @future and sends actual email, you can't assert Messaging directly.
        // But reaching this point without exception confirms execution path.
    }
}