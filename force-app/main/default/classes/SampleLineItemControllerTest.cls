@isTest
private class SampleLineItemControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account',
            CurrencyISOCode = 'USD',
            INCO_Terms__c = 'DDP'
        );
        insert testAccount;
        
        // Create Opportunity
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;
        
        // Create Sample Request
        Sample_Request__c testSampleRequest = new Sample_Request__c(
            Enquiry__c = testOpportunity.Id
        );
        insert testSampleRequest;
        
        // Create Product
        Product2 testProduct = new Product2(Name = 'Test Product');
        insert testProduct;
        
        //  Create Unit Master record
        Unit_Master__c unit = new Unit_Master__c(Name = 'Test Unit');
        insert unit;
        
        // Create Sample Out
        Sample_Out__c testSampleOut = new Sample_Out__c(
            Sample_Request__c = testSampleRequest.Id,
            Product_Name__c = testProduct.Id,
            Quantity__c = 10,
            Quality__c = 'High',
            Colour_Index_Name__c = 'CI123',
            Packets__c = 'Test Packet',
            Application__c = 'Test Application',
            Unit_of_Measure__c = 'Kilogram (Kg)',
            Sample_Sent_to_Unit__c = unit.Id
        );
        insert testSampleOut;
        
        // Create Sample In
        Sample_In__c testSampleIn = new Sample_In__c(
            Sample_Request__c = testSampleRequest.Id,
            Customer_s_Product_Name__c = 'Customer Product',
            Application__c = 'Test Application',
            Annual_Qty_of_Business__c = 100,
            Courier_Tracking_No_Date__c = 'ABC123',
            C_I__c = 'CI123',
            S_In_Ref_No__c = 'SREF001',
            VOL_Product_Name__c = testProduct.Id,
            Sample_Sent_to_Unit__c = unit.Id
        );
        insert testSampleIn;
    }
    
    @isTest
    static void testGetSampleOuts() {
        Sample_Request__c request = [SELECT Id FROM Sample_Request__c LIMIT 1];
        Test.startTest();
        List<Sample_Out__c> result = SampleLineItemController.getSampleOuts(request.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetSampleIns() {
        Sample_Request__c request = [SELECT Id FROM Sample_Request__c LIMIT 1];
        Test.startTest();
        List<Sample_In__c> result = SampleLineItemController.getSampleIns(request.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateSampleOuts() {
        // Create dependent Unit_Master__c record
        Unit_Master__c unit = new Unit_Master__c(Name = 'Unit A');
        insert unit;
        
        // Create test Sample_Out__c record
        Sample_Out__c sample = new Sample_Out__c(
           // Name = 'Test Sample',
            Quantity__c = 10,
            Quality__c = 'Good',
            Colour_Index_Name__c = 'CIN123',
          //  Packets__c = 5,
            Application__c = 'Test Application',
            Unit_of_Measure__c = 'Gram (g)',
            Sample_Sent_to_Unit__c = unit.Id
        );
        insert sample;
        
        // Modify values to test update
        sample.Quantity__c = 99;
        sample.Quality__c = 'Updated Quality';
        
        Test.startTest();
        try {
            SampleLineItemController.updateSampleOuts(new List<Sample_Out__c>{ sample });
        } catch (Exception ex) {
            System.assert(false, 'Method threw an exception: ' + ex.getMessage());
        }
        Test.stopTest();
        
        // Verify the updates
        Sample_Out__c updated = [SELECT Quantity__c, Quality__c FROM Sample_Out__c WHERE Id = :sample.Id];
        
    }
    
    
    @isTest
    static void testUpdateSampleIns() {
        Sample_In__c testSampleIn = [
            SELECT Id, Application__c, Annual_Qty_of_Business__c, C_I__c, S_In_Ref_No__c, Sample_Sent_to_Unit__c
            FROM Sample_In__c LIMIT 1
        ];
        
        // Ensure required field is set
        if (testSampleIn.Sample_Sent_to_Unit__c == null) {
            Unit_Master__c unit = [SELECT Id FROM Unit_Master__c LIMIT 1];
            testSampleIn.Sample_Sent_to_Unit__c = unit.Id;
        }
        
        testSampleIn.Application__c = 'Updated Application';
        testSampleIn.Annual_Qty_of_Business__c = 555;
        
        Test.startTest();
        SampleLineItemController.updateSampleIns(new List<Sample_In__c>{ testSampleIn });
        Test.stopTest();
        
        Sample_In__c updatedIn = [SELECT Annual_Qty_of_Business__c FROM Sample_In__c WHERE Id = :testSampleIn.Id];
    }
    
    
    @isTest
    static void testGetUnitOfMeasureOptions() {
        Test.startTest();
        List<Map<String, String>> result = SampleLineItemController.getUnitOfMeasureOptions();
        Test.stopTest();
    }
    
    @isTest
    static void testSearchUnits() {
        Test.startTest();
        List<Unit_Master__c> results = SampleLineItemController.searchUnits('Test');
        Test.stopTest();
    }
    
    @isTest
    static void testGetUnitDetails() {
        Unit_Master__c unit = [SELECT Id FROM Unit_Master__c LIMIT 1];
        Test.startTest();
        Unit_Master__c result = SampleLineItemController.getUnitDetails(unit.Id);
        Test.stopTest();
    }
}