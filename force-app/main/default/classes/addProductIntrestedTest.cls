@isTest
public class addProductIntrestedTest {

    @testSetup
    static void setupData() {
        // Create a Lead record
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'Open'
        );
        insert lead;

        // Retrieve valid picklist value for Product_Family__c
        String validPicklistValue = getValidPicklistValue('Product_Interested__c', 'Product_Family__c');

        // Create a Product Interested record
        Product_Interested__c prodInt = new Product_Interested__c(
            Lead__c = lead.Id,
            Quantity__C = 100,
            Price__c = 5000,
            Product_Family__c = validPicklistValue,
            Add_in_Opportunity__c = true
        );
        insert prodInt;
    }

    // Helper method to fetch valid picklist values (without @testSetup)
    private static String getValidPicklistValue(String objectName, String fieldName) {
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .fields
            .getMap()
            .get(fieldName)
            .getDescribe();
        
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        return picklistValues.isEmpty() ? '' : picklistValues[0].getValue();
    }

    @isTest
    static void testGetProdInterest() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        List<Id> existingProductIds = new List<Id>();

        Test.startTest();
        List<Product_Interested__c> result = addProductIntrested.getProdInterest(lead.Id, existingProductIds);
        Test.stopTest();

    }

    @isTest
    static void testDeleteProductInterested() {
        Product_Interested__c prodInt = [SELECT Id FROM Product_Interested__c LIMIT 1];

        Test.startTest();
        String result = addProductIntrested.deleteProductInterested(prodInt.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetExistingProducts() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        List<Id> productIds = addProductIntrested.getExistingProducts(lead.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        Map<String, List<Map<String, String>>> picklistValues = addProductIntrested.getPicklistValues();
        Test.stopTest();

    }

    @isTest
    static void testSaveProductInterested() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        // Get a valid picklist value dynamically
        String validPicklistValue = getValidPicklistValue('Product_Interested__c', 'Product_Family__c');

        // Create sample JSON string for new product
        String jsonStringNewProduct = '[{"inId": null, "New_Product__c": true, "New_Product_Name__c": "New Test Product", "New_Product_Description__c": "New Product Description", "volume": "200", "price": "1500", "packaging": "Box", "uom": "Unit", "prodFamily": "' + validPicklistValue + '", "Add_In_Opty": true}]';

        // Create sample JSON string for existing product
        String jsonStringExistingProduct = '[{"prodId": "01t5g000001XyZ1", "volume": "200", "price": "1500", "prodFamily": "' + validPicklistValue + '", "Add_In_Opty": true}]';

        Test.startTest();
        Map<String, String> resultNewProduct = addProductIntrested.saveProductInterested(lead.Id, jsonStringNewProduct);
        Map<String, String> resultExistingProduct = addProductIntrested.saveProductInterested(lead.Id, jsonStringExistingProduct);
        Test.stopTest();

    }
}