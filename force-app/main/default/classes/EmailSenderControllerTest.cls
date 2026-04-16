@isTest
private class EmailSenderControllerTest {

    @testSetup
    static void setupTestData() {
        
        // Create a custom test Pricebook
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;
        
        // Create Lead record
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'testlead@example.com'
        );
        insert testLead;

        // Create Product2 record
        Product2 prod = new Product2(
            Name = 'Acid Green 104',
            Family = 'Dyes',
            IsActive = true
        );
        insert prod;

        // Create standard pricebook entry (required)
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardPbe;

        // Create custom pricebook entry
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert customPbe;

        // Create Product_Interested__c records related to the Lead
        Product_Interested__c product1 = new Product_Interested__c(
            Lead__c = testLead.Id,
         
            Vipul_Product_Name__c = prod.Id,  // Correct association to Product2 Name
            Price__c = 100,
            Quantity__c = 10
        );
        insert product1;

        Product_Interested__c product2 = new Product_Interested__c(
            Lead__c = testLead.Id,
         
            Vipul_Product_Name__c = prod.Id,  // Correct association to Product2 Name
            Price__c = 200,
            Quantity__c = 5
        );
        insert product2;

        // Create attachment (ContentVersion)
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test Attachment',
            PathOnClient = 'TestAttachment.txt',
            VersionData = Blob.valueOf('Test file content')
        );
        insert contentVersion;

        // Retrieve ContentDocument from ContentVersion
        ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersion.Id LIMIT 1];

        // Link ContentDocument to the Lead
        ContentDocumentLink contentDocLink = new ContentDocumentLink(
            ContentDocumentId = contentDoc.Id,
            LinkedEntityId = testLead.Id,
            ShareType = 'V'
        );
        insert contentDocLink;
    }

    @isTest
    static void testSendEmail() {
        // Query the first Lead record
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Query the first ContentDocument record for attachment
        ContentDocument contentDoc = [SELECT Id FROM ContentDocument LIMIT 1];

        // Create list of attachment Ids
        List<Id> attachmentIds = new List<Id>{contentDoc.Id};

        // Call sendEmail method in test context
        Test.startTest();
        String result = EmailSenderController.sendEmail(testLead.Id, 'Test Subject', 'Test Body', 'test@example.com', attachmentIds);
        Test.stopTest();
    }

    @isTest
    static void testGetProducts() {
        // Query the first Lead record
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Call getProducts method to fetch related Product_Interested__c records
        Test.startTest();
        List<Product_Interested__c> products = EmailSenderController.getProducts(testLead.Id);
        Test.stopTest();
    }
}