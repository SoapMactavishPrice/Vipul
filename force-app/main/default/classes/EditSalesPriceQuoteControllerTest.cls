@isTest
public class EditSalesPriceQuoteControllerTest {

    @testSetup
    static void setup() {
        // Create test data
        User manager = new User(
            FirstName = 'Manager',
            LastName = 'Test',
            Email = 'managergbgfdfgd2332@test.com',
            Username = 'managerdsasdad232@test.com',
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
            Email = 'ownerdasdas122dw@test.com',
            Username = 'ownerasdasda232esd@test.com',
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
        
        Quote quote = new Quote(
            Name = 'Test Quote',
            Pricebook2Id = customPb.id,
            OpportunityId = opp.Id,
            OwnerId = owner.Id
        );
        insert quote;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = customPbe.Id,
            Quantity = 1,
            UnitPrice = 90,
           // ListPrice = 100,
            Purchase_Price_in_INR__c = 80,
            Purchase_Price_Status__c = 'None',
            Approval_Status__c = 'Pending'
        );
        insert qli;
    }

    @isTest
    static void testEditSalesPriceQuoteController() {
        Test.startTest();

        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PageReference pageRef = Page.EditSalesPriceQuote; // Assuming you have a Visualforce page named EditSalesPriceQuotePage
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', quote.Id);

        EditSalesPriceQuoteController controller = new EditSalesPriceQuoteController();


        // Test Save method
        controller.quoteLineItemsList[0].Approval_Status__c = 'Approved';
        controller.Save();

        // Verify changes after Save
        QuoteLineItem updatedQli = [SELECT Approval_Status__c, Approver__c FROM QuoteLineItem WHERE Id = :controller.quoteLineItemsList[0].Id];

        Test.stopTest();
    }
}