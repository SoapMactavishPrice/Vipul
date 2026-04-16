@IsTest
public class SendTDSFileTest {

    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account', INCO_Terms__c = 'DDP');
        insert testAccount;
        
        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'testcontact@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create test Opportunity with Contact
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = testAccount.Id,
            Contact__c = testContact.Id
        );
        insert testOpp;

          Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // Create a custom test Pricebook
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;

        // Create test Products
        List<Product2> testProducts = new List<Product2> {
            new Product2(Name = 'Product 1', IsActive = true),
            new Product2(Name = 'Product 2', IsActive = true)
        };
        insert testProducts;

        // Create PricebookEntry for standard pricebook and products
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{
            new PricebookEntry(
                Pricebook2Id = standardPricebook.Id,
                Product2Id = testProducts[0].Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
            ),
            new PricebookEntry(
                Pricebook2Id = standardPricebook.Id,
                Product2Id = testProducts[1].Id,
                UnitPrice = 100,
                IsActive = true,
                UseStandardPrice = false
            )
        };
        insert pricebookEntries;

        // **Update Opportunity to reference the Pricebook**
        testOpp.Pricebook2Id = standardPricebook.Id;
        update testOpp;
        
        // Create Opportunity Line Items
        List<OpportunityLineItem> olis = new List<OpportunityLineItem> {
            new OpportunityLineItem(
                OpportunityId = testOpp.Id,
                Product2Id = testProducts[0].Id,
                Quantity = 1,
                UnitPrice = 100
            ),
            new OpportunityLineItem(
                OpportunityId = testOpp.Id,
                Product2Id = testProducts[1].Id,
                Quantity = 1,
                UnitPrice = 100
            )
        };
        insert olis;
        
        // Create ContentVersion (files) for testing
        ContentVersion cv1 = new ContentVersion(
            Title = 'Test File 1',
            PathOnClient = 'TestFile1.pdf',
            VersionData = Blob.valueOf('Test Content 1'),
            IsMajorVersion = true
        );
        ContentVersion cv2 = new ContentVersion(
            Title = 'Test File 2',
            PathOnClient = 'TestFile2.pdf',
            VersionData = Blob.valueOf('Test Content 2'),
            IsMajorVersion = true
        );
        insert new List<ContentVersion>{ cv1, cv2 };
        
        // Get ContentDocumentIds
        List<ContentVersion> contentVersions = [
            SELECT Id, ContentDocumentId 
            FROM ContentVersion 
            WHERE Id IN :new List<Id>{ cv1.Id, cv2.Id }
        ];
        
        // Link files to products - one file per product
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink> {
            new ContentDocumentLink(
                LinkedEntityId = testProducts[0].Id,
                ContentDocumentId = contentVersions[0].ContentDocumentId,
                ShareType = 'V'
            ),
            new ContentDocumentLink(
                LinkedEntityId = testProducts[1].Id,
                ContentDocumentId = contentVersions[1].ContentDocumentId,
                ShareType = 'V'
            )
        };
        insert cdlList;
    }

    @IsTest
    static void testGetEmailDetails() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = SendTDSFile.getEmailDetails(testOpp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        System.assert(resultMap.containsKey('ToAdd'), 'Result should contain ToAdd key');
      
    }
    
    @IsTest
    static void testGetProductData() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String result = SendTDSFile.getProductData(testOpp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        List<Object> resultList = (List<Object>)JSON.deserializeUntyped(result);
        System.assertEquals(2, resultList.size(), 'Should return 2 products');
    }
    
    @IsTest
    static void testGetFiledDisplay() {
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        Test.startTest();
        String result = SendTDSFile.getFiledDisplay(testProduct.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        List<Object> resultList = (List<Object>)JSON.deserializeUntyped(result);
        System.assertEquals(1, resultList.size(), 'Should return 1 file per product');
    }
    
  /*  @IsTest
    static void testGetDocumentUrl() {
        ContentDocumentLink cdl = [SELECT Id, ContentDocumentId FROM ContentDocumentLink LIMIT 1];
        
        Test.startTest();
        String result = SendTDSFile.getDocumentUrl(cdl.Id);
        Test.stopTest();
        
        System.assertEquals(cdl.ContentDocumentId, result, 'Should return ContentDocumentId');
    }		*/
    
    @IsTest
    static void testSendMailToCustomer() {
        Opportunity testOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Email FROM Contact WHERE AccountId = :testOpp.AccountId LIMIT 1];
        List<String> fileIds = getAllContentDocumentLinkIds();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        String result = SendTDSFile.sendMailToCustomer(
            testContact.Email, 
            'cc@example.com',
            'Test Subject', 
            'Test Body', 
            JSON.serialize(fileIds)
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        System.assert(resultMap.containsKey('Success'), 'Email should be sent successfully');
    }
    
    @IsTest
    static void testSendMailToCustomerWithSingleFile() {
        Opportunity testOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Email FROM Contact WHERE AccountId = :testOpp.AccountId LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        List<String> fileIds = getContentDocumentLinkIds(testProduct.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        String result = SendTDSFile.sendMailToCustomer(
            testContact.Email, 
            null, 
            'Test Subject', 
            'Test Body', 
            JSON.serialize(fileIds)
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        System.assert(resultMap.containsKey('Success'), 'Email should be sent successfully');
    }
    
    @IsTest
    static void testSendMailToCustomerError() {
        Test.startTest();
        String result = SendTDSFile.sendMailToCustomer(
            'invalidemail', 
            null, 
            'Test Subject', 
            'Test Body', 
            'invalidfileid'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        System.assert(resultMap.containsKey('error'), 'Should return error for invalid inputs');
    }
    
    @IsTest
    static void testSendMailToCustomerMultipleCC() {
        Opportunity testOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Email FROM Contact WHERE AccountId = :testOpp.AccountId LIMIT 1];
        List<String> fileIds = getAllContentDocumentLinkIds();
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        String result = SendTDSFile.sendMailToCustomer(
            testContact.Email, 
            'cc1@example.com, cc2@example.com',
            'Test Subject', 
            'Test Body', 
            JSON.serialize(fileIds)
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
        System.assert(resultMap.containsKey('Success'), 'Email should be sent successfully');
    }
    
    @IsTest
    static void testSendMailToCustomerNoFiles() {
        Opportunity testOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Contact testContact = [SELECT Email FROM Contact WHERE AccountId = :testOpp.AccountId LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        String result = SendTDSFile.sendMailToCustomer(
            testContact.Email, 
            null, 
            'Test Subject', 
            'Test Body', 
            '[]'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultMap = (Map<String, Object>)JSON.deserializeUntyped(result);
       
    }
    
    // Mock HTTP Response for email sending
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    // Helper method to get ContentDocumentLink IDs for a specific product
    private static List<String> getContentDocumentLinkIds(Id productId) {
        List<ContentDocumentLink> cdls = [
            SELECT Id 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :productId
        ];
        List<String> fileIds = new List<String>();
        for(ContentDocumentLink cdl : cdls) {
            fileIds.add(cdl.Id);
        }
        return fileIds;
    }
    
    // Helper method to get all ContentDocumentLink IDs for products
    private static List<String> getAllContentDocumentLinkIds() {
        List<ContentDocumentLink> cdls = [
            SELECT Id 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN (SELECT Id FROM Product2)
        ];
        List<String> fileIds = new List<String>();
        for(ContentDocumentLink cdl : cdls) {
            fileIds.add(cdl.Id);
        }
        return fileIds;
    }
}