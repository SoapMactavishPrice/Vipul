@isTest
public class ContentDocumentLinkHandlerTest {

    @isTest
    static void testHandleAfterInsert_withSampleIn() {        
        Sample_In_Request__c sampleInRequest = new Sample_In_Request__c();
        insert sampleInRequest;
       

        // Create a child Sample_In__c record
        Sample_In__c sampleIn = new Sample_In__c(
          //  Name = 'Test Sample In',
            Sample_In_Request__c = sampleInRequest.Id
        );
        insert sampleIn;

        // Simulate an uploaded file
        ContentVersion version = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert version;

        // Retrieve the ContentDocumentId from ContentVersion
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];
        Id contentDocId = insertedVersion.ContentDocumentId;

        // Create ContentDocumentLink on the Sample_In__c record
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = sampleIn.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        // Call the handler
        Test.startTest();
        ContentDocumentLinkHandler.handleAfterInsert(new List<ContentDocumentLink>{cdl});
        Test.stopTest();

        // Assert: A new ContentDocumentLink should be created for the parent
        List<ContentDocumentLink> parentLinks = [
            SELECT Id, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :contentDocId 
              AND LinkedEntityId = :sampleInRequest.Id
        ];
        System.assertEquals(1, parentLinks.size(), 'A ContentDocumentLink should be created for the parent Sample In Request.');
    }

    @isTest
    static void testHandleAfterInsert_withSampleOut() {
        // Create a parent Sample Out Request record
        Sample_Out_Request__c sampleOutRequest = new Sample_Out_Request__c();
        

        // Create a child Sample_Out__c record
        Sample_Out__c sampleOut = new Sample_Out__c(
           // Name = 'Test Sample Out',
            Sample_Out_Request__c = sampleOutRequest.Id
        );
        insert sampleOut;

        // Simulate an uploaded file
        ContentVersion version = new ContentVersion(
            Title = 'Test File Out',
            PathOnClient = 'TestOutFile.pdf',
            VersionData = Blob.valueOf('Sample out file')
        );
        insert version;

        // Retrieve the ContentDocumentId from ContentVersion
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id];
        Id contentDocId = insertedVersion.ContentDocumentId;

        // Create ContentDocumentLink on the Sample_Out__c record
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = contentDocId,
            LinkedEntityId = sampleOut.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        // Call the handler
        Test.startTest();
        ContentDocumentLinkHandler.handleAfterInsert(new List<ContentDocumentLink>{cdl});
        Test.stopTest();

        // Assert: A new ContentDocumentLink should be created for the parent
        List<ContentDocumentLink> parentLinks = [
            SELECT Id, LinkedEntityId 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :contentDocId 
              AND LinkedEntityId = :sampleOutRequest.Id
        ];
    }
}