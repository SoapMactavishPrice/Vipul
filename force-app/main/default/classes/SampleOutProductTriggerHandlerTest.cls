@isTest
public class SampleOutProductTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create Sample_Out__c record
        Sample_Out__c sampleOut = new Sample_Out__c(
           // Product_Name__c = 'Test Product',
            Quantity__c = 10,
            Reference_Number__c = 'REF123',
            Application__c = 'Test Application',
           // Sample_Sent_to_Unit__c = 'Unit A',
            Tracking_Number__c = 'TRK123',
            Sample_Out_Status__c = 'Sample Sent to Customer',
            Quality__c = 'High',
            Packets__c = '5',
            New_Product__c = true,
            New_Product_Name__c = 'New Product A',
            New_Product_CI_No__c = 'CI123'
        );
        insert sampleOut;

        // Create an older Sample_Out_Products__c record
        Sample_Out_Products__c oldSOP = new Sample_Out_Products__c(
            Requested_Product__c = sampleOut.Id,
            //Product__c = 'Old Product',
            Quantity__c = 5,
            Reference_Number__c = 'OLDREF',
            Application__c = 'Old Application',
           // Sample_Sent_to_Unit__c = 'Old Unit',
            Tracking_Number__c = 'OLDTRK',
            Sample_Out_Status__c = 'Sample Sent to Customer',
            Quality__c = 'Medium',
            Packets__c = '2',
            New_Product__c = false,
            New_Product_Name__c = 'Old Product',
            New_Product_CI_No__c = 'OLD123'
        );
        insert oldSOP;

        // Create a newer Sample_Out_Products__c record
        Sample_Out_Products__c newSOP = new Sample_Out_Products__c(
            Requested_Product__c = sampleOut.Id,
            //Product__c = 'New Product',
            Quantity__c = 15,
            Reference_Number__c = 'NEWREF',
            Application__c = 'New Application',
            //Sample_Sent_to_Unit__c = 'New Unit',
            Tracking_Number__c = 'NEWTRK',
            Sample_Out_Status__c = 'Sample Sent to Customer',
            Quality__c = 'High',
            Packets__c = '3',
            New_Product__c = true,
            New_Product_Name__c = 'New Product B',
            New_Product_CI_No__c = 'NEW123'
        );
        insert newSOP;
    }

    @isTest
    static void testUpdateSampleInStatus() {
        // Create a Sample_In__c record
        Sample_In__c sampleIn = new Sample_In__c(Customer_s_Product_Name__c = 'Test Sample', S_In_Ref_No__c = 'vol123');
        insert sampleIn;

        // Create a Sample_Out_Products__c record with initial status
        Sample_Out_Products__c sop = new Sample_Out_Products__c(
            Sample_Out_Status__c = 'Sample Sent to Customer',
            Sample_In_Product__c = sampleIn.Id
        );
        insert sop;

        // Update the status to trigger the handler
        sop.Sample_Out_Status__c = 'Under Evaluation';
        update sop;

        // Fetch updated Sample_In__c
        Sample_In__c updatedSampleIn = [SELECT Id, Sample_In_Status__c FROM Sample_In__c WHERE Id = :sampleIn.Id];
    }

    @isTest
    static void testUpdateSampleOutStatus() {
        // Create a Sample_Out__c record
        Sample_Out__c sampleOut = new Sample_Out__c(Quantity__c = 400, Quality__c = 'STD');
        insert sampleOut;

        // Create a Sample_Out_Products__c record with initial status
        Sample_Out_Products__c sop = new Sample_Out_Products__c(
            Sample_Out_Status__c = 'Sample Sent to Customer',
            Requested_Product__c = sampleOut.Id
        );
        insert sop;

        // Update the status to trigger the handler
        sop.Sample_Out_Status__c = 'Sample Approved';
        update sop;

        // Fetch updated Sample_Out__c
        Sample_Out__c updatedSampleOut = [SELECT Id, Sample_Out_Status__c FROM Sample_Out__c WHERE Id = :sampleOut.Id];
    }
    
    @isTest
    static void testPopulateFieldsFromPreviousSampleOutForOut() {
        Sample_Out__c sampleOut = [SELECT Id FROM Sample_Out__c LIMIT 1];

        Sample_Out_Products__c newRecord = new Sample_Out_Products__c(
            Requested_Product__c = sampleOut.Id
        );

        List<Sample_Out_Products__c> newRecords = new List<Sample_Out_Products__c>{ newRecord };

        Test.startTest();
        SampleOutProductTriggerHandler.populateFieldsFromPreviousSampleOutForOut(newRecords);
        Test.stopTest();

    }

    @isTest
    static void testSyncToSampleOut() {
        Sample_Out__c sampleOut = [SELECT Id FROM Sample_Out__c LIMIT 1];

        Sample_Out_Products__c updatedSOP = new Sample_Out_Products__c(
            Requested_Product__c = sampleOut.Id,
            //Product__c = 'Updated Product',
            Quantity__c = 20,
            Reference_Number__c = 'UPDATEDREF',
            Application__c = 'Updated Application',
            //Sample_Sent_to_Unit__c = 'Updated Unit',
            Tracking_Number__c = 'UPDATEDTRK',
            Sample_Out_Status__c = 'Sample Sent to Customer',
            Quality__c = 'Premium',
            Packets__c = '6',
            New_Product__c = true,
            New_Product_Name__c = 'Updated Product Name',
            New_Product_CI_No__c = 'UPDATEDCI'
        );

        List<Sample_Out_Products__c> updatedRecords = new List<Sample_Out_Products__c>{ updatedSOP };

        Test.startTest();
        SampleOutProductTriggerHandler.syncToSampleOut(updatedRecords);
        Test.stopTest();

        Sample_Out__c updatedSampleOut = [SELECT Product_Name__c, Quantity__c, Reference_Number__c,
            Application__c, Sample_Sent_to_Unit__c, Tracking_Number__c, Sample_Out_Status__c,
            Quality__c, Packets__c, New_Product__c, New_Product_Name__c, New_Product_CI_No__c
            FROM Sample_Out__c WHERE Id = :sampleOut.Id];

    }
}