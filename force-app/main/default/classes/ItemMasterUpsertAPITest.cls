@isTest
private class ItemMasterUpsertAPITest {

    @isTest
    static void testItemMasterUpsertSuccess() {
        String jsonBody = '[{' +
            '"Name":"Test Product",' +
            '"itemCode":"ITEM001",' +
            '"itemDescription":"Test Description",' +
            '"ciNo":"CI123",' +
            '"application":"Industrial",' +
            '"unit":"PCS",' +
            '"family":"Dyes",' +
            '"segment":"Acid",' +
            '"isActive":"true"' +
        '}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/ItemMasterUpsert';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ItemMasterUpsertAPI.doPost();
        Test.stopTest();

        List<Product2> products = [SELECT Name, Item_No__c, Description, CI_no__c, Application__c, Unit__c, Family, Product_Segments__c, IsActive FROM Product2 WHERE Item_No__c = 'ITEM001'];
        List<API_Log__c> logs = [SELECT Status__c, Response_Code__c FROM API_Log__c WHERE API_log_Name__c = 'ItemMasterUpsert_API'];
    }

    @isTest
    static void testItemMasterUpsertMissingItemCode() {
        String jsonBody = '[{' +
            '"Name":"Invalid Product",' +
            '"itemDescription":"Missing itemCode"' +
        '}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/ItemMasterUpsert';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        try {
            ItemMasterUpsertAPI.doPost();
        } catch (Exception e) {
        }
        Test.stopTest();

        List<API_Log__c> logs = [SELECT Status__c, Response_Code__c FROM API_Log__c WHERE API_log_Name__c = 'ItemMasterUpsert_API' ORDER BY CreatedDate DESC LIMIT 1];
    }

    @isTest
    static void testItemMasterUpsertWithSfprodid() {
        Product2 testProd = new Product2(Name='Existing Product', Item_No__c='EXIST001');
        insert testProd;

        String jsonBody = '[{' +
            '"Name":"Updated Product",' +
            '"itemCode":"EXIST001",' +
            '"sfprodid":"' + testProd.Id + '",' +
            '"itemDescription":"Updated Description",' +
            '"ciNo":"CI456",' +
            '"application":"Textile",' +
            '"unit":"Kgs",' +
            '"family":"Acid",' +
            '"segment":"Basic",' +
            '"isActive":"false"' +
        '}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/ItemMasterUpsert';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ItemMasterUpsertAPI.doPost();
        Test.stopTest();

        List<Product2> products = [SELECT Name, Item_No__c, Description FROM Product2 WHERE Id = :testProd.Id];
        List<API_Log__c> logs = [SELECT Status__c, Response_Code__c FROM API_Log__c WHERE API_log_Name__c = 'ItemMasterUpsert_API'];
    }

    @isTest
    static void testItemMasterUpsertMultipleRecords() {
        String jsonBody = '[{' +
            '"Name":"Product 1",' +
            '"itemCode":"MULTI001",' +
            '"itemDescription":"First Product",' +
            '"ciNo":"C111",' +
            '"application":"App1",' +
            '"unit":"PCS",' +
            '"family":"Family1",' +
            '"segment":"Seg1",' +
            '"isActive":"true"' +
        '},' +
        '{' +
            '"Name":"Product 2",' +
            '"itemCode":"MULTI002",' +
            '"itemDescription":"Second Product",' +
            '"ciNo":"C222",' +
            '"application":"App2",' +
            '"unit":"BOX",' +
            '"family":"Family2",' +
            '"segment":"Seg2",' +
            '"isActive":"false"' +
        '}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/ItemMasterUpsert';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ItemMasterUpsertAPI.doPost();
        Test.stopTest();

        List<Product2> products = [SELECT Name, Item_No__c FROM Product2 WHERE Item_No__c IN ('MULTI001', 'MULTI002') ORDER BY Item_No__c];
        List<API_Log__c> logs = [SELECT Status__c, Response_Code__c FROM API_Log__c WHERE API_log_Name__c = 'ItemMasterUpsert_API'];
    }

    @isTest
    static void testItemMasterUpsertWithInvalidSfprodid() {
        String jsonBody = '[{' +
            '"Name":"Invalid ID Product",' +
            '"itemCode":"INVALID001",' +
            '"sfprodid":"001XX000003ABCD",' +
            '"itemDescription":"Product with invalid Salesforce ID",' +
            '"ciNo":"CI789",' +
            '"application":"Test",' +
            '"unit":"Ltr",' +
            '"family":"TestFamily",' +
            '"segment":"TestSeg",' +
            '"isActive":"true"' +
        '}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/ItemMasterUpsert';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ItemMasterUpsertAPI.doPost();
        Test.stopTest();

        List<Product2> products = [SELECT Name, Item_No__c FROM Product2 WHERE Item_No__c = 'INVALID001'];
        List<API_Log__c> logs = [SELECT Status__c, Response_Code__c FROM API_Log__c WHERE API_log_Name__c = 'ItemMasterUpsert_API' ORDER BY CreatedDate DESC LIMIT 1];
    }

    @isTest
    static void testItemMasterUpsertUpdateBySfprodidOnly() {
        Product2 testProd = new Product2(Name='Original Name', Item_No__c='UPDATE001');
        insert testProd;

        String jsonBody = '[{' +
            '"Name":"Updated By ID Only",' +
            '"sfprodid":"' + testProd.Id + '",' +
            '"itemDescription":"Updated without ItemCode",' +
            '"ciNo":"CI999",' +
            '"application":"Direct",' +
            '"unit":"Mtr",' +
            '"family":"DirectFamily",' +
            '"segment":"DirectSeg",' +
            '"isActive":"true"' +
        '}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/ItemMasterUpsert';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ItemMasterUpsertAPI.doPost();
        Test.stopTest();

        List<Product2> products = [SELECT Name, Item_No__c, Description FROM Product2 WHERE Id = :testProd.Id];
        List<API_Log__c> logs = [SELECT Status__c, Response_Code__c FROM API_Log__c WHERE API_log_Name__c = 'ItemMasterUpsert_API'];
    }
}