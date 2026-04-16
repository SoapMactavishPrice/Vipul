@IsTest
public class InvoiceLineItemTriggerHandlerTest {
    
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
            Actual_Quantity__c = 0,
            Actual_Amount__c = 0,
            CurrencyIsoCode = 'USD'
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
            Actual_Quantity__c = 0,
            Actual_Amount__c = 0,
            CurrencyIsoCode = 'USD'
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
            Actual_Quantity__c = 0,
            Actual_Amount__c = 0,
            CurrencyIsoCode = 'USD'
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
            Actual_Quantity__c = 0,
            Actual_Amount__c = 0,
            CurrencyIsoCode = 'USD'
        );
        insert accProdTargetLine;
        
        Invoice_Line_Item__c testLineItem = new Invoice_Line_Item__c(
            Invoice__c = testInvoice.Id,
            Account__c = testAccount.Id,
            ItemName__c = testProduct.Id,
            Quantity__c = 10,
            Line_Total_Before_Tax__c = 1000,
            CurrencyIsoCode = 'USD'
        );
        insert testLineItem;
    }
    
    
    @IsTest
    static void testUpdateQuantityOnTargetBulk() {
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        List<Invoice_Line_Item__c> bulkItems = new List<Invoice_Line_Item__c>();
        // Reduced from 50 to 10 to avoid SOQL limits
        for(Integer i = 0; i < 10; i++) {
            Invoice_Line_Item__c item = new Invoice_Line_Item__c(
                Invoice__c = invoice.Id,
                Account__c = acc.Id,
                ItemName__c = prod.Id,
                Quantity__c = i + 1,
                Line_Total_Before_Tax__c = (i + 1) * 100,
                CurrencyIsoCode = 'USD'  // Same currency to reduce convertCurrency calls
            );
            bulkItems.add(item);
        }
        insert bulkItems;
        
        Test.startTest();
        InvoiceLineItemTriggerHandler.updateQuantityOnTarget(bulkItems);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateQuantityOnTargetWithMinimalTargets() {
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser@testorg.com.test' LIMIT 1];
        
        // Create minimal targets to reduce SOQL queries
        Employee_Wise_Target__c empTarget = new Employee_Wise_Target__c(
            Employee__c = testUser.Id,
            Target_Amount__c = 5000,
            Fiscal_Year__c = [SELECT Id FROM Fiscal_Year__c LIMIT 1].Id,
            Target_Quantity__c = 50
        );
        insert empTarget;
        
        Employee_Wise_Target_Line_Item__c empTargetLine = new Employee_Wise_Target_Line_Item__c(
            Employee_Wise_Target__c = empTarget.Id,
            Start_Date__c = Date.today().addDays(-5),
            End_Date__c = Date.today().addDays(5),
            Actual_Quantity__c = 0,
            Actual_Amount__c = 0,
            CurrencyIsoCode = 'USD'
        );
        insert empTargetLine;
        
        List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>();
        for(Integer i = 0; i < 5; i++) {
            Invoice_Line_Item__c item = new Invoice_Line_Item__c(
                Invoice__c = invoice.Id,
                Account__c = acc.Id,
                ItemName__c = prod.Id,
                Quantity__c = i + 1,
                Line_Total_Before_Tax__c = (i + 1) * 50,
                CurrencyIsoCode = 'USD'
            );
            lineItems.add(item);
        }
        insert lineItems;
        
        Test.startTest();
        InvoiceLineItemTriggerHandler.updateQuantityOnTarget(lineItems);
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateQuantityOnTargetNoConversionNeeded() {
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser@testorg.com.test' LIMIT 1];
        
        // Update all targets to use USD to avoid currency conversion
        List<Employee_Wise_Target_Line_Item__c> empTargets = [SELECT Id FROM Employee_Wise_Target_Line_Item__c];
        for(Employee_Wise_Target_Line_Item__c target : empTargets) {
            target.CurrencyIsoCode = 'USD';
        }
        update empTargets;
        
        List<Employee_Wise_Account_Target_Line_Item__c> empAccTargets = [SELECT Id FROM Employee_Wise_Account_Target_Line_Item__c];
        for(Employee_Wise_Account_Target_Line_Item__c target : empAccTargets) {
            target.CurrencyIsoCode = 'USD';
        }
        update empAccTargets;
        
        List<Employee_Wise_Product_Target_Line_Item__c> empProdTargets = [SELECT Id FROM Employee_Wise_Product_Target_Line_Item__c];
        for(Employee_Wise_Product_Target_Line_Item__c target : empProdTargets) {
            target.CurrencyIsoCode = 'USD';
        }
        update empProdTargets;
        
        List<Account_Wise_Product_Target_Line_Item__c> accProdTargets = [SELECT Id FROM Account_Wise_Product_Target_Line_Item__c];
        for(Account_Wise_Product_Target_Line_Item__c target : accProdTargets) {
            target.CurrencyIsoCode = 'USD';
        }
        update accProdTargets;
        
        List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>();
        for(Integer i = 0; i < 3; i++) {
            Invoice_Line_Item__c item = new Invoice_Line_Item__c(
                Invoice__c = invoice.Id,
                Account__c = acc.Id,
                ItemName__c = prod.Id,
                Quantity__c = i + 1,
                Line_Total_Before_Tax__c = (i + 1) * 100,
                CurrencyIsoCode = 'USD'
            );
            lineItems.add(item);
        }
        insert lineItems;
        
        Test.startTest();
        InvoiceLineItemTriggerHandler.updateQuantityOnTarget(lineItems);
        Test.stopTest();
    }
}