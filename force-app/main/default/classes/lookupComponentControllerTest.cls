@IsTest
public class lookupComponentControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create sample Products
        List<Product2> productList = new List<Product2>();
        for (Integer i = 1; i <= 3; i++) {
            productList.add(new Product2(
                Name = 'Test Product ' + i,
                ProductCode = 'P00' + i,
                Family = 'Electronics'
            ));
        }
        insert productList;
    }

    @IsTest
    static void testFindRecords() {
        Test.startTest();
        List<SObject> results = lookupComponentController.findRecords(
            null, null, 'Test', 'Product2', null, 
            'ProductCode',  // Avoid adding "Family"
            null, null, null, // Removed 'Family' from displayFields
            'Name', '5', true, 'Electronics'
        );
        Test.stopTest();
        
        System.assertNotEquals(0, results.size(), 'Expected some records to be returned');
    }

    @IsTest
    static void testFetchDefaultRecord() {
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        SObject result = lookupComponentController.fetchDefaultRecord(testProduct.Id, 'Product2', 'ProductCode'); // Avoid duplicate 'Name'
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Expected a valid Product2 record');
    }
}