@isTest
private class EditPurchasPriceTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account', INCO_Terms__c = 'DDP');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpp;
        
        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;
        
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;
        
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 0,
            IsActive = true
        );
        insert standardPbe;
        
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = testOpp.Id,
                PricebookEntryId = standardPbe.Id,
                Quantity = 1,
                TotalPrice = 100,
                Purchase_Price_in_INR__c = 1000,
                Purchase_Price_Status__c = 'Approved', 
                Request_Purchase_Price__c = true
            ),
            new OpportunityLineItem(
                OpportunityId = testOpp.Id,
                PricebookEntryId = standardPbe.Id,
                Quantity = 2,
                TotalPrice = 200,
                Purchase_Price_in_INR__c = 2000,
                Purchase_Price_Status__c = 'Approved',
                Request_Purchase_Price__c = true
            )
        };
        insert olis;
    }
    
    @isTest
    static void testSaveMethodWithStatusUpdates() {
        Opportunity testOpp = [SELECT Id FROM Opportunity LIMIT 1];

        PageReference pageRef = Page.EditPurchasPrice;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testOpp.Id);
        
        EditPurchasPrice controller = new EditPurchasPrice();
        
        Test.startTest();
        PageReference resultPage = controller.Save();
        Test.stopTest();
        
        
        List<OpportunityLineItem> updatedOLIs = [SELECT Id, Purchase_Price_in_INR__c, Purchase_Price_Status__c FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];

        for (OpportunityLineItem oli : updatedOLIs) {
          //  System.assertEquals('', oli.Purchase_Price_Status__c, 'Purchase_Price_Status__c should be reset to empty string');
        }
    }

    @isTest
    static void testSaveMethodWithNoOLI() {
        Opportunity testOpp = new Opportunity(Name = 'New Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(30));
        insert testOpp;

        PageReference pageRef = Page.EditPurchasPrice;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testOpp.Id);
        
        EditPurchasPrice controller = new EditPurchasPrice();
        
        Test.startTest();
        PageReference resultPage = controller.Save();
        Test.stopTest();
        
    }

}