@isTest
private class ProductTriggerHandlerTest {
    
    @testSetup
    static void setupData() {
        
        // ✅ Get Standard Pricebook correctly
        Id stdPricebookId = Test.getStandardPricebookId();
        
        // Activate it
        Pricebook2 stdPb = new Pricebook2(
            Id = stdPricebookId,
            IsActive = true
        );
        update stdPb;
        
        // Existing product for duplicate testing
        Product2 existingProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            IsActive = true
        );
        insert existingProduct;
    }

    // 🔹 Duplicate Name Test
    @isTest
    static void testPreventDuplicateByName() {
        Product2 duplicateNameProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'UniqueCode1',
            IsActive = true
        );

        Test.startTest();
        try {
            insert duplicateNameProduct;
            System.assert(false, 'Expected duplicate name error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('same Name'));
        }
        Test.stopTest();
    }

    // 🔹 Duplicate Code Test
    @isTest
    static void testPreventDuplicateByCode() {
        Product2 duplicateCodeProduct = new Product2(
            Name = 'Unique Product',
            ProductCode = 'TP001',
            IsActive = true
        );

        Test.startTest();
        try {
            insert duplicateCodeProduct;
            System.assert(false, 'Expected duplicate code error');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('same Product Code'));
        }
        Test.stopTest();
    }

    // 🔹 Valid Insert + PricebookEntry Creation
    @isTest
    static void testCreatePricebookEntry_OnInsert() {

        Product2 prod = new Product2(
            Name = 'PB Product',
            ProductCode = 'PB001',
            IsActive = true,
            Create_PricebookEntry__c = true // IMPORTANT
        );

        Test.startTest();
        insert prod;
        Test.stopTest();

        // Verify PricebookEntry created
        List<PricebookEntry> pbeList = [
            SELECT Id, Product2Id
            FROM PricebookEntry
            WHERE Product2Id = :prod.Id
        ];

        System.assert(pbeList.size() > 0, 'PricebookEntry should be created');
    }

    // 🔹 Update Scenario (false → true)
    @isTest
    static void testCreatePricebookEntry_OnUpdate() {

        Product2 prod = new Product2(
            Name = 'Update PB Product',
            ProductCode = 'PB002',
            IsActive = true,
            Create_PricebookEntry__c = false
        );
        insert prod;

        // Update flag to TRUE
        prod.Create_PricebookEntry__c = true;

        Test.startTest();
        update prod;
        Test.stopTest();

        List<PricebookEntry> pbeList = [
            SELECT Id
            FROM PricebookEntry
            WHERE Product2Id = :prod.Id
        ];

        System.assert(pbeList.size() > 0, 'PricebookEntry should be created on update');
    }
}