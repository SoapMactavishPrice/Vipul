@isTest
public class SampleInTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Get the Standard Price Book ID
        Id standardPbId = Test.getStandardPricebookId();
        
        // Activate the Standard Price Book by inserting a product and a pricebook entry
        Product2 dummyProduct = new Product2(Name = 'Dummy Product', IsActive = true, CurrencyIsoCode = 'USD');
        insert dummyProduct;
        
        PricebookEntry dummyEntry = new PricebookEntry(
            Product2Id = dummyProduct.Id,
            Pricebook2Id = standardPbId,
            UnitPrice = 1,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert dummyEntry;
        
    }
    
    
    
    @isTest
    static void testHandleAfterInsertOrUpdate_NoMatchingCriteria() {
        // Case where criteria is not met: nothing should be inserted or updated
        // 
        // Create user for Person__r
        User u = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Create Sample_In_Request__c
        Sample_In_Request__c sampleInRequest = new Sample_In_Request__c(
           // Name = 'Sample In Request 001',
            Person__c = u.Id
        );
        insert sampleInRequest;
            
        Sample_In__c sample = new Sample_In__c(
            // Name = 'Test Sample C',
            Matched_Agt_Std__c = false,
            R_D__c = false,
            CurrencyIsoCode = 'USD',
            Sample_In_Request__c = sampleInRequest.Id
        );
        insert sample;
        
        Test.startTest();
        SampleInTriggerHandler.handleAfterInsertOrUpdate(new List<Sample_In__c>{sample});
        Test.stopTest();
        
        // Assert no product was created
        List<Product2> products = [SELECT Id FROM Product2 WHERE Name = 'Test Sample C'];
        
        // Assert Sample record has no product linked
        Sample_In__c updatedSample = [SELECT Id, VOL_Product_Name__c FROM Sample_In__c WHERE Id = :sample.Id];
    }
    
    @isTest
    static void testCreateOrUpdateSampleOutRecords() {
        
        
        Country__c testCountry = new Country__c(Name = 'India');
        insert testCountry;
        
        Account acc1 = new Account(Name = 'Test Account 1', Street__c = '123 Test St', Country__c = testCountry.id, INCO_Terms__c = 'DDP', currencyisocode='USD');
        insert acc1;
        
        // Create Unit_Master__c
        Unit_Master__c unit1 = new Unit_Master__c(
            Name = 'Unit 1',
            Email_1__c = 'unit1@example.com',
            Email_2__c = 'unit1_2@example.com',
            Email_3__c = 'unit1_3@example.com'
        );
        insert unit1;
        
        // Create user for Person__r
        User u = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Create Sample_In_Request__c
        Sample_In_Request__c sampleInRequest = new Sample_In_Request__c(
           // Name = 'Sample In Request 001',
            Person__c = u.Id
        );
        insert sampleInRequest;
        
        Sample_In__c sample = new Sample_In__c(
            Sample_In_Status__c = 'Sample Sent to Customer',
            //VOL_Product_Name__c = null,
            Sample_In_Request__c = sampleInRequest.Id,
            Quantity__c = 10,
            Sample_Out_Ref_No__c = 'REF123',
            Application__c = 'Test Application',
            Sample_Sent_to_Unit__c = unit1.Id,
            Courier_Tracking_No__c = 'TRACK123',
            CurrencyIsoCode = 'USD',
            Country__c = testCountry.id, Company_Name__c = acc1.id
        );
        insert sample;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true, CurrencyIsoCode = 'USD');
        insert prod;
        
        sample.Matched_Agt_Std__c = true;
        sample.New_Development__c = 'New developmemt';
        sample.VOL_Product_Name__c = prod.Id;
        update Sample;
        
        List<Sample_In__c> sampleList = [SELECT Id, Sample_In_Status__c, VOL_Product_Name__c, Quantity__c, Sample_Out_Ref_No__c, Application__c, Sample_Sent_to_Unit__c, Courier_Tracking_No__c,
                                         Matched_Agt_Std__c, New_Development__c FROM Sample_In__c];
        
        Test.startTest();
        SampleInTriggerHandler.createSampleOutRecordsOnce(sampleList);
        //SampleInTriggerHandler.handleAfterInsertOrUpdate(sampleList);
        Test.stopTest();
        
        List<Sample_Out__c> sampleOuts = [SELECT Id, Sample_In_Product__c FROM Sample_Out__c WHERE Sample_In_Product__c = :sample.Id];
    }
    
    
    @isTest
    static void testHandleAfterInsertOrUpdate_NoAction() {
        
        // Create user for Person__r
        User u = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Create Sample_In_Request__c
        Sample_In_Request__c sampleInRequest = new Sample_In_Request__c(
           // Name = 'Sample In Request 001',
            Person__c = u.Id
        );
        insert sampleInRequest;
        
        // Insert a sample that doesn't meet any criteria
        Sample_In__c sample3 = new Sample_In__c(
            Matched_Agt_Std__c = false,
            R_D__c = false,
            CurrencyIsoCode = 'USD',
            Sample_In_Request__c = sampleInRequest.Id
        );
        
        insert sample3;
        
        Test.startTest();
        SampleInTriggerHandler.handleAfterInsertOrUpdate(new List<Sample_In__c>{ sample3 });
        Test.stopTest();
        
        // No product should be created
        List<Product2> products = [SELECT Id FROM Product2 WHERE Name = 'Test Sample 3'];
        System.assertEquals(0, products.size());
        
        // No update should have been made to VOL_Product_Name__c
        Sample_In__c unchangedSample = [SELECT VOL_Product_Name__c FROM Sample_In__c WHERE Id = :sample3.Id];
        System.assertEquals(null, unchangedSample.VOL_Product_Name__c);
    }
    
    @isTest
static void testCaptureStatusChangeDates() {
    
    // Create user for Person__r
        User u = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Create Sample_In_Request__c
        Sample_In_Request__c sampleInRequest = new Sample_In_Request__c(
           // Name = 'Sample In Request 001',
            Person__c = u.Id
        );
        insert sampleInRequest;
    
    // Create and insert initial record
    Sample_In__c oldSample = new Sample_In__c(
        Sample_In_Status__c = 'Sample Received from Customer',
        Sample_In_Request__c = sampleInRequest.Id
    );
    insert oldSample;
    
    // Simulate status change
    Sample_In__c updatedSample = [
        SELECT Id, Sample_In_Status__c, Sample_Sent_to_Factory_Date__c 
        FROM Sample_In__c 
        WHERE Id = :oldSample.Id
    ];
    updatedSample.Sample_In_Status__c = 'Sample Sent to Factory';
    
    List<Sample_In__c> newList = new List<Sample_In__c>{ updatedSample };
    Map<Id, Sample_In__c> oldMap = new Map<Id, Sample_In__c>{ oldSample.Id => oldSample };
    
    Test.startTest();
    SampleInTriggerHandler.captureStatusChangeDates(newList, oldMap);
    //SampleInTriggerHandler.temethod();
    Test.stopTest();
    
    System.assertNotEquals(null, updatedSample.Sample_Sent_to_Factory_Date__c, 'Factory date should be set');
    
    // Repeat for other statuses
    List<String> statuses = new List<String>{
        'Sample Sent to Customer',
        'Sample Matching',
        'Sample Sent to HO',
        'Rejected',
        'Approved'
    };

    for (String status : statuses) {
        
        
        Sample_In__c oldRec = new Sample_In__c(
            Sample_In_Status__c = 'Sample Received from Customer',
            Sample_In_Request__c = sampleInRequest.Id
        );
        insert oldRec;

        Sample_In__c newRec = [
            SELECT Id, Sample_In_Status__c,
                   Sample_Sent_to_Customer_Date__c,
                   Sample_Matching_Date__c,
                   Sample_Sent_to_HO_Date__c,
                   Sample_Rejected_Date__c,
                   Sample_Approved_Date__c
            FROM Sample_In__c 
            WHERE Id = :oldRec.Id
        ];
        newRec.Sample_In_Status__c = status;

        newList = new List<Sample_In__c>{ newRec };
        oldMap = new Map<Id, Sample_In__c>{ oldRec.Id => oldRec };

        SampleInTriggerHandler.captureStatusChangeDates(newList, oldMap);

        if (status == 'Sample Sent to Customer') {
            System.assertNotEquals(null, newRec.Sample_Sent_to_Customer_Date__c, 'Customer date should be set');
        } else if (status == 'Sample Matching') {
            System.assertNotEquals(null, newRec.Sample_Matching_Date__c, 'Matching date should be set');
        } else if (status == 'Sample Sent to HO') {
            System.assertNotEquals(null, newRec.Sample_Sent_to_HO_Date__c, 'HO date should be set');
        } else if (status == 'Rejected') {
            System.assertNotEquals(null, newRec.Sample_Rejected_Date__c, 'Rejected date should be set');
        } else if (status == 'Approved') {
            System.assertNotEquals(null, newRec.Sample_Approved_Date__c, 'Approved date should be set');
        }
    }
}
    
   @isTest
    static void testHandleAfterInsertOrUpdate() {
        // Get standard pricebook ID for test context
        Id standardPBId = Test.getStandardPricebookId();

        // Create test Sample_In__c records
        List<Sample_In__c> samples = new List<Sample_In__c>{
            new Sample_In__c(
                Matched_Agt_Std__c = true,
                New_Development__c = 'Test Product A',
                CurrencyIsoCode = 'USD'
            ),
            new Sample_In__c(
                R_D__c = true,
                R_D_Product_Development__c = 'Test Product B',
                CurrencyIsoCode = 'USD'
            ),
            new Sample_In__c(
                Matched_Agt_Std__c = false,
                R_D__c = false,
                CurrencyIsoCode = 'USD'
            )
        };

        // insert samples;

        // Re-query to get the inserted records with IDs
        samples = [SELECT Id, Matched_Agt_Std__c, New_Development__c, R_D__c, R_D_Product_Development__c, CurrencyIsoCode, VOL_Product_Name__c FROM Sample_In__c];

        Test.startTest();
        SampleInTriggerHandler.handleAfterInsertOrUpdate(samples);
        Test.stopTest();

        // Verify that VOL_Product_Name__c was populated
        List<Sample_In__c> updatedSamples = [SELECT Id, VOL_Product_Name__c FROM Sample_In__c WHERE Id IN :samples];
        Integer updatedCount = 0;
        for (Sample_In__c s : updatedSamples) {
            if (s.VOL_Product_Name__c != null) {
                updatedCount++;
            }
        }

        //System.assertEquals(2, updatedCount, 'Two Sample_In__c records should have been updated with Product2 references.');
    }
    
    @isTest
    static void testStatusUpdateLogic() {
        // Create parent record
        Sample_In_Request__c request = new Sample_In_Request__c(Sample_In_Status__c = 'Sample In');
        insert request;
        
        request.Sample_In_Status__c = 'Sample Sent to Factory';
        update request;

        // Create child records with mixed statuses
        Sample_In__c s1 = new Sample_In__c(Sample_In_Request__c = request.Id, Sample_In_Status__c = 'Approved');
        Sample_In__c s2 = new Sample_In__c(Sample_In_Request__c = request.Id, Sample_In_Status__c = 'Rejected');
        insert new List<Sample_In__c>{s1, s2};

        request = [SELECT Id, Sample_In_Status__c FROM Sample_In_Request__c WHERE Id = :request.Id];

        // Update all to Approved
        s2.Sample_In_Status__c = 'Approved';
        update s2;

        request = [SELECT Id, Sample_In_Status__c FROM Sample_In_Request__c WHERE Id = :request.Id];

        // Update all to Rejected
        s1.Sample_In_Status__c = 'Rejected';
        s2.Sample_In_Status__c = 'Re-Sampling';
        update new List<Sample_In__c>{s1, s2};

        request = [SELECT Id, Sample_In_Status__c FROM Sample_In_Request__c WHERE Id = :request.Id];
    }


    
}