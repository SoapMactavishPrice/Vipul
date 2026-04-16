@isTest
public class SampleOutTriggerHandlerTest {
    
    @isTest
    static void testCaptureStatusChangeDates() {
        // Step 1: Create initial Sample_Out__c record with a default status
        Sample_Out_Request__c request = new Sample_Out_Request__c(
            Sample_Request_Status__c = 'Sample Request From Factory'
        );
        insert request;
        
        Sample_Out__c sample = new Sample_Out__c(
            Sample_Out_Status__c = 'Sample Sent to Customer',
            Sample_Out_Request__c = request.Id
        );
        insert sample;
        
        // Step 2: Simulate status change
        Sample_Out__c updatedSample = sample.clone(false, true, false, false);
        updatedSample.Id = sample.Id;
        updatedSample.Sample_Out_Status__c = 'Sample Sent to HO';
        
        Test.startTest();
        SampleOutTriggerHandler.captureStatusChangeDates(
            new List<Sample_Out__c>{updatedSample},
            new Map<Id, Sample_Out__c>{sample.Id => sample}
        );
        Test.stopTest();
        
    }
    
    @isTest
    static void testCaptureStatusChangeDates1() {
        // Step 1: Create initial Sample_Out__c record with a default status
        
        Sample_Out_Request__c request = new Sample_Out_Request__c(
            Sample_Request_Status__c = 'Sample Request From Factory'
        );
        insert request;
        
        Sample_Out__c sample = new Sample_Out__c(
            Sample_Out_Status__c = 'Sample Rejected',
            Sample_Out_Request__c = request.Id
        );
        insert sample;
        
        // Step 2: Simulate status change
        Sample_Out__c updatedSample = sample.clone(false, true, false, false);
        updatedSample.Id = sample.Id;
        updatedSample.Sample_Out_Status__c = 'Sample Approved';
        
        Test.startTest();
        SampleOutTriggerHandler.captureStatusChangeDates(
            new List<Sample_Out__c>{updatedSample},
            new Map<Id, Sample_Out__c>{sample.Id => sample}
        );
        Test.stopTest();
        
    }
    
    @isTest
    static void testCreateOrUpdateSampleOutRecords_InsertAndUpdate() {
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;
        
        Unit_Master__c unit = new Unit_Master__c(Name = 'AM', Email_1__c = 'ankit@gmail.com');
        insert unit;
        
        Sample_Out_Request__c request = new Sample_Out_Request__c(
            Sample_Request_Status__c = 'Sample Request From Factory'
        );
        insert request;

        Sample_Out__c sampleOut1 = new Sample_Out__c(
            Product_Name__c = testProduct.Id,
            Quantity__c = 10,
            Reference_Number__c = 'REF001',
            Application__c = 'App A',
            Sample_Sent_to_Unit__c = unit.id,
            Tracking_Number__c = 'TRK001',
            Sample_Out_Status__c = 'Sample Sent to Customer',
            Packets__c = '2',
            New_Product__c = false,
            New_Product_Name__c = 'New Product A',
            New_Product_CI_No__c = 'CI001',
            Sample_Out_Request__c = request.Id
        );

        Sample_Out__c sampleOut2 = new Sample_Out__c(
            New_Product_Name__c = 'New Product B',
            Quantity__c = 5,
            Reference_Number__c = 'REF002',
            Application__c = 'App B',
            Sample_Sent_to_Unit__c = unit.Id,
            Tracking_Number__c = 'TRK002',
            Sample_Out_Status__c = 'Sample Sent to Customer',
            Packets__c = '1',
            New_Product__c = true,
            New_Product_CI_No__c = 'CI002',
            Sample_Out_Request__c = request.Id
        );

        insert new List<Sample_Out__c>{ sampleOut1, sampleOut2 };

        List<Sample_Out_Products__c> insertedRecords = [
            SELECT Id, Requested_Product__c, Product__c, New_Product_Name__c
            FROM Sample_Out_Products__c
            WHERE Requested_Product__c IN :new List<Id>{ sampleOut1.Id, sampleOut2.Id }
        ];
        System.assertEquals(2, insertedRecords.size());

        sampleOut1.Quantity__c = 20;
        update sampleOut1;

        Test.startTest();
        SampleOutTriggerHandler.createSampleOutRecords(new List<Sample_Out__c>{ sampleOut1, sampleOut2 });
        SampleOutTriggerHandler.createSampleOutRecords(new List<Sample_Out__c>{ sampleOut1 });
        Test.stopTest();

        Sample_Out_Products__c updatedRecord = [
            SELECT Id, Quantity__c
            FROM Sample_Out_Products__c
            WHERE Requested_Product__c = :sampleOut1.Id
        ];
        System.assertEquals(20, updatedRecord.Quantity__c);
    }
    
    @isTest
    static void testStatusUpdateLogic() {
        // Create parent record
        Sample_Out_Request__c request = new Sample_Out_Request__c(Sample_Request_Status__c = 'Sample Request');
        insert request;
        
        request.Sample_Request_Status__c = 'Sample Request From Factory';
        update request;

        // Create child records with mixed statuses
        Sample_Out__c s1 = new Sample_Out__c(Sample_Out_Request__c = request.Id, Sample_Out_Status__c = 'Sample Approved');
        Sample_Out__c s2 = new Sample_Out__c(Sample_Out_Request__c = request.Id, Sample_Out_Status__c = 'Sample Rejected');
        insert new List<Sample_Out__c>{s1, s2};

        request = [SELECT Id, Sample_Request_Status__c FROM Sample_Out_Request__c WHERE Id = :request.Id];

        // Update all to Approved
        s2.Sample_Out_Status__c = 'Sample Approved';
        update s2;

        request = [SELECT Id, Sample_Request_Status__c FROM Sample_Out_Request__c WHERE Id = :request.Id];

        // Update all to Rejected
        s1.Sample_Out_Status__c = 'Sample Rejected';
        s2.Sample_Out_Status__c = 'Re-Sampling';
        update new List<Sample_Out__c>{s1, s2};

        request = [SELECT Id, Sample_Request_Status__c FROM Sample_Out_Request__c WHERE Id = :request.Id];
    }
}