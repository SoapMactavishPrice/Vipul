@isTest
private class ProformaInvoiceControllerTest {
    @isTest
    static void testCreateProformaInvoice() {
        Test.startTest();
        
        // Step 1: Get Standard Pricebook
        Id PID = Test.getStandardPricebookId();
        
        // Step 2: Define the Currency Code (Ensure it's valid)
        String currencyCode = 'USD'; // Change this to match your org settings
        
        // Step 3: Create a Product
        Product2 product = new Product2(
            Name = 'Test Product',
            IsActive = TRUE
        );
        insert product;
        
        // Step 4: Define Standard Pricebook Entry with Matching Currency
        PricebookEntry standardPBE = new PricebookEntry(
            Pricebook2Id = PID,
            Product2Id = product.Id,
            UnitPrice = 220,
            IsActive = TRUE,
            UseStandardPrice = FALSE,
            CurrencyIsoCode = currencyCode // Ensure Currency Consistency
        );
        insert standardPBE;
        
        // Step 5: Create a Custom Pricebook
        Pricebook2 customPricebook = new Pricebook2(
            Name = 'Custom Price Book',
            IsActive = TRUE,
            CurrencyIsoCode = currencyCode // Ensure the same currency
        );
        insert customPricebook;
        
        // Step 6: Create a Pricebook Entry in Custom Pricebook
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = customPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 220,
            IsActive = TRUE,
            CurrencyIsoCode = currencyCode // Ensure it matches the Quote currency
        );
        insert pbe;
        
        // Step 7: Create an Account with Matching Currency
        Account account = new Account(
            Name = 'Test Account',
            INCO_Terms__c = 'DDP',
            CurrencyIsoCode = currencyCode // Ensure consistency
        );
        insert account;
        
        Check_List__c check = new Check_List__c(
        	Name = 'Test',
            Account__c = account.Id,
            SO_Date__c = Date.today().addDays(1),
            SO_No__c = 'SO123'

        );
        insert check;
        
        // Step 8: Create an Opportunity with Matching Currency
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(30),
            AccountId = account.Id,
            CurrencyIsoCode = currencyCode // Ensure consistency
        );
        insert opp;
        
        // Step 9: Create a Quote with Matching Currency
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = customPricebook.Id,
            Status = 'Draft',
            ExpirationDate = System.today().addDays(15),
            CurrencyIsoCode = currencyCode // Ensure it matches the PricebookEntry
        );
        insert quote;
        
        // Step 10: Create a Quote Line Item with Matching Currency
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Quantity = 5,
            UnitPrice = 200,
            Discount = 10,
            PricebookEntryId = pbe.Id, // Ensure PBE has the same currency
            Description = 'Test QLI Description',
            Packing_Type__c = 'HDPE Bag'
            //CurrencyIsoCode = currencyCode // Ensure consistency
        );
        insert qli;


        // Step 10: Simulate the Page Reference and Controller
        Test.setCurrentPageReference(new PageReference('/apex/ProformaInvoicePage'));
        ApexPages.currentPage().getParameters().put('quoteId', quote.Id);

        // Step 11: Instantiate the Controller and Call Method
        ProformaInvoiceController controller = new ProformaInvoiceController();
        PageReference result = controller.createProformaInvoice();

        Test.stopTest();

        // Step 12: Assertions to Validate Proforma Invoice Creation
        List<Proforma_Invoice__c> invoices = [SELECT Id, Quote__c FROM Proforma_Invoice__c WHERE Quote__c = :quote.Id];

        List<Proforma_Invoice_Line_Item__c> lineItems = [SELECT Id FROM Proforma_Invoice_Line_Item__c WHERE Proforma_Invoice_Name__c = :invoices[0].Id];
    }
}