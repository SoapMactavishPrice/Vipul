@isTest
public class EditSalesPriceControllerTest {
    
    @testSetup
    static void setup() {
        // Create test data
        User manager = new User(
            FirstName = 'Manager',
            LastName = 'Test',
            Email = 'manager765765757@test.com',
            Username = 'managerffhfhgb34234242@test.com',
            Alias = 'mgrtest',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert manager;
        
        User owner = new User(
            FirstName = 'Owner',
            LastName = 'Test',
            Email = 'owner223422432dsd@test.com',
            Username = 'ownersdfsdfds23232@test.com',
            Alias = 'owntest',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LanguageLocaleKey = 'en_US',
            ManagerId = manager.Id
        );
        insert owner;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            OwnerId = owner.Id
        );
        insert opp;
        
        Product2 product = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            IsActive = true
        );
        insert product;
        
        // Create custom price book
        Pricebook2 customPb = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert customPb;
        
        // Get standard price book ID
        Id standardPricebookId = Test.getStandardPricebookId();
        
        
        // Create price book entries
        PricebookEntry standardPbe = new PricebookEntry(Product2Id = product.Id, Pricebook2Id = standardPricebookId, UnitPrice = 100, IsActive = true);
        insert standardPbe;
        
        PricebookEntry customPbe = new PricebookEntry(Product2Id = product.Id, Pricebook2Id = customPb.Id, UnitPrice = 100, IsActive = true);
        insert customPbe;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = customPbe.Id,
            Quantity = 1,
            UnitPrice = 90,
            //ListPrice = 100,
            Purchase_Price_in_INR__c = 80,
            Purchase_Price_Status__c = 'Rejected',
            Approval_Status__c = 'Pending'
        );
        insert oli;
    }
    
    @isTest
    static void testEditSalesPriceController() {
        Test.startTest();
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PageReference pageRef = Page.EditSalesPrice; // Assuming you have a Visualforce page named EditSalesPricePage
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        
        EditSalesPriceController controller = new EditSalesPriceController();
        
        
        // Test Save method
        controller.oppList[0].Approval_Status__c = 'Approved';
        controller.Save();
        
        // Verify changes after Save
        OpportunityLineItem updatedOli = [SELECT Approval_Status__c, Approver__c FROM OpportunityLineItem WHERE Id = :controller.oppList[0].Id];
        
        Test.stopTest();
    }
}