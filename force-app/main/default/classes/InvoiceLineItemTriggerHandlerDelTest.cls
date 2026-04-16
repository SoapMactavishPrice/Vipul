@IsTest
public class InvoiceLineItemTriggerHandlerDelTest {
    
    @TestSetup
    static void setupTestData() {
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@testorg.com.test'
        );
        insert testUser;
        
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'Test Fiscal Year',
            FY_Start_Date__c = Date.today().addMonths(-6),
            FY_End_Date__c = Date.today().addMonths(6)
        );
        insert fy;
        
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            OwnerId = testUser.Id
        );
        insert testOrder;
        
        Invoice__c testInvoice = new Invoice__c(
            Name = 'Test Invoice',
            Account__c = testAccount.Id,
            Order__c = testOrder.Id,
            ARI_Date__c = Date.today()
        );
        insert testInvoice;
        
        Employee_Wise_Target__c empTarget = new Employee_Wise_Target__c(
            Employee__c = testUser.Id,
            Target_Amount__c = 10000,
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 100
        );
        insert empTarget;
        
        Employee_Wise_Target_Line_Item__c empTargetLine = new Employee_Wise_Target_Line_Item__c(
            Employee_Wise_Target__c = empTarget.Id,
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(10),
            Actual_Quantity__c = 50,
            Actual_Amount__c = 5000
        );
        insert empTargetLine;
        
        Employee_Wise_Account_Target__c empAccTarget = new Employee_Wise_Account_Target__c(
            Employee__c = testUser.Id,
            Account__c = testAccount.Id,
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 50,
            Target_Amount__c = 5000
        );
        insert empAccTarget;
        
        Employee_Wise_Account_Target_Line_Item__c empAccTargetLine = new Employee_Wise_Account_Target_Line_Item__c(
            Employee_Wise_Account_Target__c = empAccTarget.Id,
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(10),
            Actual_Quantity__c = 30,
            Actual_Amount__c = 3000
        );
        insert empAccTargetLine;
        
        Employee_Wise_Product_Target__c empProdTarget = new Employee_Wise_Product_Target__c(
            Employee__c = testUser.Id,
            Product__c = testProduct.Id,
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 30,
            Target_Amount__c = 3000
        );
        insert empProdTarget;
        
        Employee_Wise_Product_Target_Line_Item__c empProdTargetLine = new Employee_Wise_Product_Target_Line_Item__c(
            Employee_Wise_Product_Target__c = empProdTarget.Id,
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(10),
            Actual_Quantity__c = 20,
            Actual_Amount__c = 2000
        );
        insert empProdTargetLine;
        
        Account_Wise_Product_Target__c accProdTarget = new Account_Wise_Product_Target__c(
            Account__c = testAccount.Id,
            Product__c = testProduct.Id,
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 20,
            Target_Amount__c = 2000
        );
        insert accProdTarget;
        
        Account_Wise_Product_Target_Line_Item__c accProdTargetLine = new Account_Wise_Product_Target_Line_Item__c(
            Account_Wise_Product_Target__c = accProdTarget.Id,
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(10),
            Actual_Quantity__c = 15,
            Actual_Amount__c = 1500
        );
        insert accProdTargetLine;
        
        Invoice_Line_Item__c testLineItem = new Invoice_Line_Item__c(
            Invoice__c = testInvoice.Id,
            Account__c = testAccount.Id,
            ItemName__c = testProduct.Id,
            Quantity__c = 10,
            Line_Total_Before_Tax__c = 1000
        );
        insert testLineItem;
    }
    
    @IsTest
    static void testDeleteTriggerCoverage() {
        List<Invoice_Line_Item__c> lineItems = [
            SELECT Id FROM Invoice_Line_Item__c
        ];
        
        Test.startTest();
        delete lineItems;
        Test.stopTest();
    }
    
    @IsTest
    static void testDeleteMultipleItemsTriggerCoverage() {
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser@testorg.com.test' LIMIT 1];
        
        Order secondOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            OwnerId = testUser.Id
        );
        insert secondOrder;
        
        Invoice__c secondInvoice = new Invoice__c(
            Name = 'Second Invoice',
            Account__c = acc.Id,
            Order__c = secondOrder.Id,
            ARI_Date__c = Date.today()
        );
        insert secondInvoice;
        
        List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>();
        for(Integer i = 0; i < 3; i++) {
            Invoice_Line_Item__c item = new Invoice_Line_Item__c(
                Invoice__c = secondInvoice.Id,
                Account__c = acc.Id,
                ItemName__c = prod.Id,
                Quantity__c = i + 1,
                Line_Total_Before_Tax__c = (i + 1) * 100
            );
            lineItems.add(item);
        }
        insert lineItems;
        
        Test.startTest();
        delete lineItems;
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateQuantityOnTargetDelete() {
        List<Invoice_Line_Item__c> lineItems = [
            SELECT Id, Account__c, ItemName__c, Quantity__c, Line_Total_Before_Tax__c, 
                   Invoice__r.Order__r.OwnerId, Invoice__r.ARI_Date__c,CurrencyIsoCode
            FROM Invoice_Line_Item__c
        ];
        
        Test.startTest();
        InvoiceLineItemTriggerHandlerDel.updateQuantityOnTargetDelete(lineItems);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateQuantityOnTargetDeleteEmptyList() {
        Test.startTest();
        InvoiceLineItemTriggerHandlerDel.updateQuantityOnTargetDelete(new List<Invoice_Line_Item__c>());
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateQuantityOnTargetDeleteNullList() {
        Test.startTest();
        InvoiceLineItemTriggerHandlerDel.updateQuantityOnTargetDelete(null);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateQuantityOnTargetDeleteDateOutOfRange() {
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];
        invoice.ARI_Date__c = Date.today().addYears(-5);
        update invoice;
        
        List<Invoice_Line_Item__c> lineItems = [
            SELECT Id, Account__c, ItemName__c, Quantity__c, Line_Total_Before_Tax__c, 
                   Invoice__r.Order__r.OwnerId, Invoice__r.ARI_Date__c,CurrencyIsoCode
            FROM Invoice_Line_Item__c WHERE Invoice__c = :invoice.Id
        ];
        
        Test.startTest();
        InvoiceLineItemTriggerHandlerDel.updateQuantityOnTargetDelete(lineItems);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateQuantityOnTargetDeleteZeroValues() {
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        Invoice_Line_Item__c lineItem = new Invoice_Line_Item__c(
            Invoice__c = invoice.Id,
            Account__c = acc.Id,
            ItemName__c = prod.Id,
            Quantity__c = 0,
            Line_Total_Before_Tax__c = 0
        );
        insert lineItem;
        
        List<Invoice_Line_Item__c> lineItems = [
            SELECT Id, Account__c, ItemName__c, Quantity__c, Line_Total_Before_Tax__c, 
                   Invoice__r.Order__r.OwnerId, Invoice__r.ARI_Date__c,CurrencyIsoCode
            FROM Invoice_Line_Item__c WHERE Id = :lineItem.Id
        ];
        
        Test.startTest();
        InvoiceLineItemTriggerHandlerDel.updateQuantityOnTargetDelete(lineItems);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateQuantityOnTargetDeleteNoTargets() {
        Account newAccount = new Account(Name = 'New Account');
        insert newAccount;
        
        Product2 newProduct = new Product2(Name = 'New Product', IsActive = true);
        insert newProduct;
        
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser@testorg.com.test' LIMIT 1];
        
        Order newOrder = new Order(
            AccountId = newAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            OwnerId = testUser.Id
        );
        insert newOrder;
        
        Invoice__c newInvoice = new Invoice__c(
            Name = 'New Invoice',
            Account__c = newAccount.Id,
            Order__c = newOrder.Id,
            ARI_Date__c = Date.today()
        );
        insert newInvoice;
        
        Invoice_Line_Item__c newLineItem = new Invoice_Line_Item__c(
            Invoice__c = newInvoice.Id,
            Account__c = newAccount.Id,
            ItemName__c = newProduct.Id,
            Quantity__c = 5,
            Line_Total_Before_Tax__c = 500
        );
        insert newLineItem;
        
        List<Invoice_Line_Item__c> lineItems = [
            SELECT Id, Account__c, ItemName__c, Quantity__c, Line_Total_Before_Tax__c, 
                   Invoice__r.Order__r.OwnerId, Invoice__r.ARI_Date__c,CurrencyIsoCode
            FROM Invoice_Line_Item__c WHERE Id = :newLineItem.Id
        ];
        
        Test.startTest();
        InvoiceLineItemTriggerHandlerDel.updateQuantityOnTargetDelete(lineItems);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateQuantityOnTargetDeleteWithNoMatchingOwner() {
        User newUser = new User(
            Alias = 'newuser',
            Email = 'newuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NewUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'newuser@testorg.com.test'
        );
        insert newUser;
        
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        Order newOrder = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            OwnerId = newUser.Id
        );
        insert newOrder;
        
        Invoice__c newInvoice = new Invoice__c(
            Name = 'New User Invoice',
            Account__c = acc.Id,
            Order__c = newOrder.Id,
            ARI_Date__c = Date.today()
        );
        insert newInvoice;
        
        Invoice_Line_Item__c newLineItem = new Invoice_Line_Item__c(
            Invoice__c = newInvoice.Id,
            Account__c = acc.Id,
            ItemName__c = prod.Id,
            Quantity__c = 5,
            Line_Total_Before_Tax__c = 500
        );
        insert newLineItem;
        
        List<Invoice_Line_Item__c> lineItems = [
            SELECT Id, Account__c, ItemName__c, Quantity__c, Line_Total_Before_Tax__c, 
                   Invoice__r.Order__r.OwnerId, Invoice__r.ARI_Date__c,CurrencyIsoCode
            FROM Invoice_Line_Item__c WHERE Id = :newLineItem.Id
        ];
        
        Test.startTest();
        InvoiceLineItemTriggerHandlerDel.updateQuantityOnTargetDelete(lineItems);
        Test.stopTest();
    }
}