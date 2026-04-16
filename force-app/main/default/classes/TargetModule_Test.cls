@isTest
public class TargetModule_Test {

    @isTest
    static void employeeWiseTarget() {
        // Create a Fiscal Year record
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2025, 1, 1),
            FY_End_Date__c = Date.newInstance(2025, 12, 31)
            
        );
        insert fy;

        // Create Product records
        List<Product2> products = new List<Product2>();
        
            products.add(new Product2(Name = 'VOXCO CHROME ORANGE VO-750/SA ' , Family = 'VO ' ));
            products.add(new Product2(Name = 'VOXCO ZINC PHOSPHATE ' , Family = 'Anti-Corrosive ' ));
            
        insert products;

        // Create Account records
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Account ' + i));
        }
        insert accounts;

        List<Employee_Wise_Target__c> empTargets = new List<Employee_Wise_Target__c>();
        for (Integer i = 0; i < 5; i++) {
            empTargets.add(new Employee_Wise_Target__c(
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 100 * i,
                Target_Amount__c = 1000 * i
            ));
        }
        insert empTargets;
        // Create Employee Wise Product Target records
        
        List<Employee_Wise_Product_Target__c> prodTargets = new List<Employee_Wise_Product_Target__c>();
        for (Product2 prod : products) {
            prodTargets.add(new Employee_Wise_Product_Target__c(
                Product__c = prod.Id,
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 200 * products.indexOf(prod),
                Target_Amount__c = 2000 * products.indexOf(prod)
            ));
        }
        insert prodTargets;

        // Create Employee Wise Account Target records
        List<Employee_Wise_Account_Target__c> accTargets = new List<Employee_Wise_Account_Target__c>();
        for (Account acc : accounts) {
            accTargets.add(new Employee_Wise_Account_Target__c(
                Account__c = acc.Id,
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 300 * accounts.indexOf(acc),
                Target_Amount__c = 3000 * accounts.indexOf(acc)
            ));
        }
        insert accTargets;
        
         List<Account_Wise_Product_Target__c> accprodTargets = new List<Account_Wise_Product_Target__c>();
        for (Account acc : accounts) {
            accprodTargets.add(new Account_Wise_Product_Target__c(
                Account__c = acc.Id,
              //  Product__c = acc.id,
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 300 * accounts.indexOf(acc),
                Target_Amount__c = 3000 * accounts.indexOf(acc)
            ));
        }
        insert accprodTargets;
        
        Test.startTest();
        TargetModule.getDefaultFilterValues();
        String result = TargetModule.getYearly(null , fy.Id, userinfo.getUserId(), 'Employee_Wise_Target__c', null,null);
        String result1 = TargetModule.getYearly(null , fy.Id, userinfo.getUserId(), 'Employee_Wise_Product_Target__c', null,null);
        String result2 = TargetModule.getYearly(null , fy.Id, userinfo.getUserId(), 'Employee_Wise_Account_Target__c', null,null);
        String result3 = TargetModule.getYearly(null , fy.Id, userinfo.getUserId(), 'Account_Wise_Product_Target__c', null,null);
        Test.stopTest();
    }
    @IsTest
    static void testGetYearly_EmployeeWiseProductTarget() {
        // Create a Fiscal Year record
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
            
        );
        insert fy;

        // Create Product records
        List<Product2> products = new List<Product2>();
        
            products.add(new Product2(Name = 'VOXCO CHROME ORANGE VO-750/SA ' , Family = 'VO ' ));
            products.add(new Product2(Name = 'VOXCO ZINC PHOSPHATE ' , Family = 'Anti-Corrosive ' ));
            
        insert products;

        // Create Account records
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Account ' + i));
        }
        insert accounts;

        List<Employee_Wise_Target__c> empTargets = new List<Employee_Wise_Target__c>();
        for (Integer i = 0; i < 5; i++) {
            empTargets.add(new Employee_Wise_Target__c(
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 100 * i,
                Target_Amount__c = 1000 * i
            ));
        }
        // Create Employee Wise Product Target records
        
        List<Employee_Wise_Product_Target__c> prodTargets = new List<Employee_Wise_Product_Target__c>();
        for (Product2 prod : products) {
            prodTargets.add(new Employee_Wise_Product_Target__c(
                Product__c = prod.Id,
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 200 * products.indexOf(prod),
                Target_Amount__c = 2000 * products.indexOf(prod)
            ));
        }
        insert prodTargets;

        // Create Employee Wise Account Target records
        List<Employee_Wise_Account_Target__c> accTargets = new List<Employee_Wise_Account_Target__c>();
        for (Account acc : accounts) {
            accTargets.add(new Employee_Wise_Account_Target__c(
                Account__c = acc.Id,
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 300 * accounts.indexOf(acc),
                Target_Amount__c = 3000 * accounts.indexOf(acc)
            ));
        }
        insert accTargets;
        
        List<Account_Wise_Product_Target__c> accprodTargets = new List<Account_Wise_Product_Target__c>();
        for (Account acc : accounts) {
            accprodTargets.add(new Account_Wise_Product_Target__c(
                Account__c = acc.Id,
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 300 * accounts.indexOf(acc),
                Target_Amount__c = 3000 * accounts.indexOf(acc)
            ));
        }
        insert accprodTargets;
        
        Test.startTest();
        String result = TargetModule.getYearly(null , fy.Id, userinfo.getUserId(), 'Employee_Wise_Target__c', null,null);
         String result1 = TargetModule.getYearly(null , fy.Id, userinfo.getUserId(), 'Employee_Wise_Product_Target__c', null,null);
         String result2 = TargetModule.getYearly(null , fy.Id, userinfo.getUserId(), 'Employee_Wise_Account_Target__c', null,null);
        String result3 = TargetModule.getYearly(null , fy.Id, userinfo.getUserId(), 'Account_Wise_Product_Target__c', null,null);
        Test.stopTest();
    }
    @IsTest
    static void testGetYearly_EmployeeWiseAccountTarget() {
         // Create a Fiscal Year record
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
            
        );
        insert fy;

        // Create Product records
        List<Product2> products = new List<Product2>();
        
            products.add(new Product2(Name = 'VOXCO CHROME ORANGE VO-750/SA ' , Family = 'VO ' ));
            products.add(new Product2(Name = 'VOXCO ZINC PHOSPHATE ' , Family = 'Anti-Corrosive ' ));
            
        insert products;

        // Create Account records
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Account ' + i));
        }
        insert accounts;

        List<Employee_Wise_Target__c> empTargets = new List<Employee_Wise_Target__c>();
        for (Integer i = 0; i < 5; i++) {
            empTargets.add(new Employee_Wise_Target__c(
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 100 * i,
                Target_Amount__c = 1000 * i
            ));
        }
        
        
        // Create Employee Wise Product Target records
        
        List<Employee_Wise_Product_Target__c> prodTargets = new List<Employee_Wise_Product_Target__c>();
        for (Product2 prod : products) {
            prodTargets.add(new Employee_Wise_Product_Target__c(
                Product__c = prod.Id,
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 200 * products.indexOf(prod),
                Target_Amount__c = 2000 * products.indexOf(prod)
            ));
        }
        insert prodTargets;

        // Create Employee Wise Account Target records
        List<Employee_Wise_Account_Target__c> accTargets = new List<Employee_Wise_Account_Target__c>();
        for (Account acc : accounts) {
            accTargets.add(new Employee_Wise_Account_Target__c(
                Account__c = acc.Id,
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 300 * accounts.indexOf(acc),
                Target_Amount__c = 3000 * accounts.indexOf(acc)
            ));
        }
        insert accTargets;
        
        List<Account_Wise_Product_Target__c> accprodTargets = new List<Account_Wise_Product_Target__c>();
        for (Account acc : accounts) {
            accprodTargets.add(new Account_Wise_Product_Target__c(
                Account__c = acc.Id,
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 300 * accounts.indexOf(acc),
                Target_Amount__c = 3000 * accounts.indexOf(acc)
            ));
        }
        insert accprodTargets;
        
        Test.startTest();
        String result = TargetModule.getYearly(null, fy.Id, userinfo.getUserId(), 'Employee_Wise_Target__c', null,null);
         String result1 = TargetModule.getYearly(null, fy.Id, userinfo.getUserId(), 'Employee_Wise_Product_Target__c', null,null);
         String result2 = TargetModule.getYearly(null, fy.Id, userinfo.getUserId(), 'Employee_Wise_Account_Target__c', null,null);
        String result3 = TargetModule.getYearly(null, fy.Id, userinfo.getUserId(), 'Account_Wise_Product_Target__c', null,null);
        Test.stopTest();
    }
    @isTest
    static void testGetMonthly() {
        
        // Fiscal Year
        Fiscal_Year__c fiscalYear = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
        );
        insert fiscalYear;

        // Employee (User)
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Product
        Product2 product = new Product2(Name = 'VOXCO CHROME ORANGE VO-750/SA', Family = 'VO');
        insert product;

        // Account
        Account account = new Account(Name = 'Test Account');
        insert account;
        
        
        Employee_Wise_Target__c emt = new Employee_Wise_Target__c(
                Employee__c = UserInfo.getUserId(),
            	Account__c = account.id,
                Fiscal_Year__c = fiscalYear.Id,
                Target_Quantity__c = 100 ,
                Target_Amount__c = 1000 
            );
        
        insert emt;
    
        Employee_Wise_Target_Line_Item__c TargetLineItem = new Employee_Wise_Target_Line_Item__c(
            Employee_Wise_Target__c = emt.Id,
            Start_Date__c = Date.newInstance(2024, 1, 1),
            End_Date__c = Date.newInstance(2024, 1, 31),
            Monthly_Target_Quantity__c = 100,
            Monthly_Target_Amount__c = 1000
        );
        insert TargetLineItem;
        
        
        // Employee Wise Product Target
        Employee_Wise_Product_Target__c productTarget = new Employee_Wise_Product_Target__c(
            Employee__c = user.Id,
            Product__c = product.Id,
            Fiscal_Year__c = fiscalYear.Id,
            Target_Quantity__c= 100,
            Target_Amount__c=1000
        );
        
        insert productTarget;

        // Employee Wise Product Target Line Item
        Employee_Wise_Product_Target_Line_Item__c productTargetLineItem = new Employee_Wise_Product_Target_Line_Item__c(
            Employee_Wise_Product_Target__c = productTarget.Id,
            Start_Date__c = Date.newInstance(2024, 1, 1),
            End_Date__c = Date.newInstance(2024, 1, 31),
            Monthly_Target_Quantity__c = 100,
            Monthly_Target_Amount__c = 1000
        );
        insert productTargetLineItem;

        // Employee Wise Account Target
        Employee_Wise_Account_Target__c accountTarget = new Employee_Wise_Account_Target__c(
            Employee__c = user.Id,
            Account__c = account.Id,
            Fiscal_Year__c = fiscalYear.Id,
            Target_Quantity__c= 100,
            Target_Amount__c=1000
        );
        insert accountTarget;

        // Employee Wise Account Target Line Item
        Employee_Wise_Account_Target_Line_Item__c accountTargetLineItem = new Employee_Wise_Account_Target_Line_Item__c(
            Employee_Wise_Account_Target__c = accountTarget.Id,
            Start_Date__c = Date.newInstance(2024, 1, 1),
            End_Date__c = Date.newInstance(2024, 1, 31),
            Monthly_Target_Quantity__c = 200,
            Monthly_Target_Amount__c = 2000
        );
        insert accountTargetLineItem;
        
         Account_Wise_Product_Target__c accountprodTarget = new Account_Wise_Product_Target__c(
            Employee__c = user.Id,
            Account__c = account.Id,
            Fiscal_Year__c = fiscalYear.Id,
            Target_Quantity__c= 100,
            Target_Amount__c=1000
        );
        insert accountprodTarget;
        
         Account_Wise_Product_Target_Line_Item__c accountprodTargetLineItem = new Account_Wise_Product_Target_Line_Item__c(
            Account_Wise_Product_Target__c = accountprodTarget.id,
            Start_Date__c = Date.newInstance(2024, 1, 1),
            End_Date__c = Date.newInstance(2024, 1, 31),
            Monthly_Target_Quantity__c = 200,
            Monthly_Target_Amount__c = 2000
        );
        insert accountprodTargetLineItem;

        // Test cases
        Test.startTest();

        String resultTarget = TargetModule.getMonthly(fiscalYear.Id, user.Id, 'Employee_Wise_Target__c', null,null);

        String resultProductTarget = TargetModule.getMonthly(fiscalYear.Id, user.Id, 'Employee_Wise_Product_Target__c', null,null);
        String resultAccountTarget = TargetModule.getMonthly(fiscalYear.Id, user.Id, 'Employee_Wise_Account_Target__c', null,null);
      String resultAccountProdTarget = TargetModule.getMonthly(fiscalYear.Id, user.Id, 'Account_Wise_Product_Target__c', null,account.Id);
        
        String resultBlankFiscId = TargetModule.getMonthly('', user.Id, 'Employee_Wise_Product_Target__c', null,null);
        String resultBlankParentTab = TargetModule.getMonthly(fiscalYear.Id, user.Id, '', null,null);
        
        Test.stopTest();
    }
    @isTest
    static void testSaveRecordsYearly() {
        // Set up test data
        Fiscal_Year__c fiscalYear = new Fiscal_Year__c(
            Name = 'FY 2024',
            FY_Start_Date__c = Date.newInstance(2024, 1, 1),
            FY_End_Date__c = Date.newInstance(2024, 12, 31)
        );
        insert fiscalYear;

        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Product2 product = new Product2(Name = 'Test Product', Family = 'Test Family');
        insert product;

        Account account = new Account(Name = 'Test Account');
        insert account;

        // Prepare JSON data for Yearly subType
        String yearlyData = '[{"ParameterId":"' + user.Id + '","Target_Amount_New__c":"1000","Target_Quantity_New__c":"100"}]';
        String yearlyProductData = '[{"ParameterId":"' + product.Id + '","Target_Amount_New__c":"2000","Target_Quantity_New__c":"200"}]';
        String yearlyAccountData = '[{"ParameterId":"' + account.Id + '","Target_Amount_New__c":"3000","Target_Quantity_New__c":"300"}]';
        
        // Test 'Employee_Wise_Target__c'
        Test.startTest();
        String result = TargetModule.saveRecords(yearlyData, fiscalYear.Id, user.Id, 'Employee_Wise_Target__c', 'Yearly',null);
        result = TargetModule.saveRecords(yearlyProductData, fiscalYear.Id, user.Id, 'Employee_Wise_Product_Target__c', 'Yearly',null);
        result = TargetModule.saveRecords(yearlyProductData, fiscalYear.Id, user.Id, 'Employee_Wise_Account_Target__c', 'Yearly',null);
        result = TargetModule.saveRecords(yearlyProductData, fiscalYear.Id, user.Id, 'Account_Wise_Product_Target__c', 'Yearly',null);
       
        Test.stopTest();
        
    }

    @isTest
    static void testSaveRecordsMonthly() {
        // Set up test data
        Fiscal_Year__c fiscalYear = new Fiscal_Year__c(
            Name = 'FY 2024',
            FY_Start_Date__c = Date.newInstance(2024, 1, 1),
            FY_End_Date__c = Date.newInstance(2024, 12, 31)
        );
        insert fiscalYear;

        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Product2 product = new Product2(Name = 'Test Product', Family = 'Test Family');
        insert product;

        Account account = new Account(Name = 'Test Account');
        insert account;

        // Prepare JSON data for Monthly subType
        String monthlyData = '[{"ParameterId":"' + user.Id + '","Monthly_Target_Amount__c":"100","Monthly_Target_Quantity__c":"10"}]';
        String monthlyProductData = '[{"ParameterId":"' + product.Id + '","Monthly_Target_Amount__c":"200","Monthly_Target_Quantity__c":"20"}]';
        String monthlyAccountData = '[{"ParameterId":"' + account.Id + '","Monthly_Target_Amount__c":"300","Monthly_Target_Quantity__c":"30"}]';
        
        
        Test.startTest();
        String result = TargetModule.saveRecords(monthlyData, fiscalYear.Id, user.Id, 'Employee_Wise_Target__c', 'Monthly',null);
        result = TargetModule.saveRecords(monthlyProductData, fiscalYear.Id, user.Id, 'Employee_Wise_Product_Target__c', 'Monthly',null);
        result = TargetModule.saveRecords(monthlyAccountData, fiscalYear.Id, user.Id, 'Employee_Wise_Account_Target__c', 'Monthly',null);
        result = TargetModule.saveRecords(monthlyAccountData, fiscalYear.Id, user.Id, 'Account_Wise_Product_Target__c', 'Monthly',null);
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetTargetQuantityByEmpId() {
        
        //User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
            
        );
        insert fy;
        
        try {
            Employee_Wise_Target__c ewt = new Employee_Wise_Target__c(
                Fiscal_Year__c=fy.Id,
                Employee__c = UserInfo.getUserId(),
                Target_Quantity__c = 10,
                Target_Amount__c=100
            );
            
            insert ewt;
        } catch (DmlException e) {
            System.assert(false, 'Employee_Wise_Target__c record insertion failed.');
        }
        Test.startTest();
        // Call the method with a valid employee ID
     //   String result = TargetModule.getTargetQuantityByEmpId(UserInfo.getUserId());
        //result = TargetModule.getTargetQuantityByEmpId('nonexistent-id');
        Test.stopTest();
 
    }
    
    @isTest
    static void testGetTargetAmountByEmpId() {
        
        //User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
            
        );
        insert fy;
        
        try {
            Employee_Wise_Target__c ewt = new Employee_Wise_Target__c(
                Fiscal_Year__c=fy.Id,
                Employee__c = UserInfo.getUserId(),
                Target_Quantity__c = 10,
                Target_Amount__c=100
            );
            
            insert ewt;
        } catch (DmlException e) {
            System.assert(false, 'Employee_Wise_Target__c record insertion failed.');
        }
        Test.startTest();
        // Call the method with a valid employee ID
     //   String result = TargetModule.getTargetAmountByEmpId(UserInfo.getUserId());
        //result = TargetModule.getTargetQuantityByEmpId('nonexistent-id');
        Test.stopTest();
 
    }

 /*   @isTest
    static void testGetProductTargetQtyByProdCatVal() {
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
            
        );
        insert fy;
        // Create Account records
        Account acc=  new Account(Name = 'Account ' );
        insert acc;
        
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        String empId = user.Id;
        String prodCatVal = 'TestProductCategory';

       
            // Insert Employee_Wise_Account_Target__c record
            Employee_Wise_Account_Target__c ewat = new Employee_Wise_Account_Target__c(
                Fiscal_Year__c=fy.Id,
                Account__c = acc.Id,
                Employee__c = empId,
                Target_Quantity__c = 200,
                Target_Amount__c=1000
            );
            
            insert ewat;
        
         Account_Wise_Product_Target__c ewapt = new Account_Wise_Product_Target__c(
                Fiscal_Year__c=fy.Id,
                Account__c = acc.Id,
                Employee__c = empId,
                Target_Quantity__c = 200,
                Target_Amount__c=1000
            );
            
            insert ewapt;
        Test.startTest();
  //      String result = TargetModule.getProductTargetQtyByProdCatVal(prodCatVal, empId);
        Test.stopTest();
        
    }	*/
    
      @isTest
    static void testGetDefaultFilterValues() {
        // Create test fiscal year
       // Create test fiscal year
         Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2025, 1, 1),
            FY_End_Date__c = Date.newInstance(2025, 12, 31)
            
        );
        insert fy;

        Test.startTest();
        String resultJson = TargetModule.getDefaultFilterValues();
        Test.stopTest();

        System.debug('Returned JSON: ' + resultJson);
        System.assertNotEquals(null, resultJson, 'Result should not be null');
        System.assert(resultJson.contains(fy.Id), 'Response should include fiscal year ID');
    }
    
    @isTest
    static void testGetTargetQuantityByEmpId1() {
        // Create test user
    //    User testUser = [SELECT Id FROM User WHERE Profile.Name = 'Standard User' LIMIT 1];

        // Create test fiscal year
         Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
            
        );
        insert fy;

        List<Employee_Wise_Target__c> empTarget = new List<Employee_Wise_Target__c>();
        for (Integer i = 0; i < 5; i++) {
            empTarget.add(new Employee_Wise_Target__c(
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 100 * i,
                Target_Amount__c = 1000 * i
            ));
        }
        insert empTarget;
      //  insert empTarget;

        Test.startTest();
        String result = TargetModule.getTargetQuantityByEmpId(userinfo.getUserId(), fy.Id);
        Test.stopTest();

      //  System.assertEquals('123', result, 'The returned target quantity should match the inserted value.');
    }
    
     @isTest
    static void testGetTargetAmountByEmpId11() {
        // Create Fiscal Year
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
        );
        insert fy;

        // Create Employee Wise Target records
        Employee_Wise_Target__c empTarget = new Employee_Wise_Target__c(
            Employee__c = UserInfo.getUserId(),
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 100,
            Target_Amount__c = 1000
        );
        insert empTarget;

        // Test getTargetAmountByEmpId
        Test.startTest();
        String result = TargetModule.getTargetAmountByEmpId(UserInfo.getUserId(), fy.Id);
        Test.stopTest();

    //    System.assertEquals('1000', result, 'The target amount should match the inserted value.');
    }

    @isTest
    static void testGetTargetAmountByaccId() {
        // Create Fiscal Year
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
        );
        insert fy;

        // Create Account records
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Account ' + i));
        }
        insert accounts;

        // Create Employee Wise Account Target records
        List<Employee_Wise_Account_Target__c> accTargets = new List<Employee_Wise_Account_Target__c>();
        for (Account acc : accounts) {
            accTargets.add(new Employee_Wise_Account_Target__c(
                Account__c = acc.Id,
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 300 * accounts.indexOf(acc),
                Target_Amount__c = 3000 * accounts.indexOf(acc)
            ));
        }
        insert accTargets;
        
        // Create test Users
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testusewqwq1212r@example.com',
            Username = 'testuserwqwq112@example.com.testclass',
            Alias = 'tuser',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = p.Id,
            IsActive = true
        );
        insert testUser;

        // Test getTargetAmountByaccId for all accounts in a single test run
        Test.startTest();
        String result;

        result = TargetModule.getTargetAmountByaccId(accounts[0].Id, fy.Id, testUser.id);
    //    System.assertEquals('0', result, 'The target amount should match the inserted value for Account 0.');

        //result = TargetModule.getTargetAmountByaccId(accounts[1].Id, fy.Id);
     //   System.assertEquals('3000', result, 'The target amount should match the inserted value for Account 1.');

       // result = TargetModule.getTargetAmountByaccId(accounts[4].Id, fy.Id);
     //   System.assertEquals('12000', result, 'The target amount should match the inserted value for Account 4.');

        Test.stopTest();
    }
      @isTest
    static void testGetProductTargetAmtByProdCatValAmt() {
        // Create Fiscal Year
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
        );
        insert fy;

        // Create Product records
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'VOXCO CHROME ORANGE VO-750/SA', Family = 'VO'));
        products.add(new Product2(Name = 'VOXCO ZINC PHOSPHATE', Family = 'Anti-Corrosive'));
        insert products;

        // Create Account records
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Account ' + i));
        }
        insert accounts;

        // Create Account Wise Product Target records
        List<Account_Wise_Product_Target__c> accprodTargets = new List<Account_Wise_Product_Target__c>(); 
        for (Account acc : accounts) {
            accprodTargets.add(new Account_Wise_Product_Target__c(
                Account__c = acc.Id,
                Employee__c = UserInfo.getUserId(),
                Fiscal_Year__c = fy.Id,
                Target_Quantity__c = 300 * accounts.indexOf(acc),
                Target_Amount__c = 3000 * accounts.indexOf(acc)
            ));
        }
        insert accprodTargets;

        // Test getProductTargetAmtByProdCatValAmt method for first product and second account
        Test.startTest();
        String result = TargetModule.getProductTargetAmtByProdCatValAmt(
            products[0].Id,  // Product ID
            UserInfo.getUserId(),  // Employee ID (using current user)
            accounts[1].Id,  // Account ID
            fy.Id  // Fiscal Year ID
        );
        Test.stopTest();

       
    }
    
/*    @isTest
    static void testIsSystemAdministrator() {
        Test.startTest();
        Boolean isAdmin = TargetModule.isSystemAdministrator();
        Test.stopTest();
    }	*/

    @isTest
    static void testGetYearly_AccountWiseProductTarget() {
        // Create a Fiscal Year record
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
        );
        insert fy;

        // Create Product records
        Product2 product = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST123',
            Description = 'Test Description'
        );
        insert product;

        // Create Account records
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Account Wise Product Target record
        Account_Wise_Product_Target__c awpt = new Account_Wise_Product_Target__c(
            Account__c = acc.Id,
            Product__c = product.Id,
            Employee__c = UserInfo.getUserId(),
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 100,
            Target_Amount__c = 1000,
            Product_Code__c = product.ProductCode,
            Description__c = product.Description
        );
        insert awpt;

        Test.startTest();
        String result = TargetModule.getYearly(null, fy.Id, UserInfo.getUserId(), 'Account_Wise_Product_Target__c', null, null);
        Test.stopTest();

        // Verify the result contains the expected data
        System.assert(result.contains('Test Product'), 'Response should include product name');
        System.assert(result.contains('TEST123'), 'Response should include product code');
        System.assert(result.contains('Test Description'), 'Response should include product description');
    }

    @isTest
    static void testGetTargetQuantityByaccId() {
        // Create Fiscal Year
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
        );
        insert fy;

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Employee Wise Account Target
        Employee_Wise_Account_Target__c ewat = new Employee_Wise_Account_Target__c(
            Account__c = acc.Id,
            Employee__c = UserInfo.getUserId(),
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 500,
            Target_Amount__c = 5000
        );
        insert ewat;

        Test.startTest();
        String result = TargetModule.getTargetQuantityByaccId(acc.Id, fy.Id, UserInfo.getUserId());
        Test.stopTest();

    }

    @isTest
    static void testGetProductTargetQtyByProdCatVal() {
        // Create Fiscal Year
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
        );
        insert fy;

        // Create Product
        Product2 product = new Product2(Name = 'Test Product');
        insert product;

        // Create Employee Wise Product Target
        Employee_Wise_Product_Target__c ewpt = new Employee_Wise_Product_Target__c(
            Product__c = product.Id,
            Employee__c = UserInfo.getUserId(),
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 200,
            Target_Amount__c = 2000
        );
        insert ewpt;

        Test.startTest();
        String result = TargetModule.getProductTargetQtyByProdCatVal(product.Id, UserInfo.getUserId(), fy.Id);
        Test.stopTest();

    }

    @isTest
    static void testGetProductTargetQtyByProdCatValAmt() {
        // Create Fiscal Year
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY 2026',
            FY_Start_Date__c = Date.newInstance(2026, 1, 1),
            FY_End_Date__c = Date.newInstance(2026, 12, 31)
        );
        insert fy;

        // Create Product and Account
        Product2 product = new Product2(Name = 'Test Product');
        insert product;
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Account Wise Product Target
        Account_Wise_Product_Target__c awpt = new Account_Wise_Product_Target__c(
            Product__c = product.Id,
            Account__c = acc.Id,
            Employee__c = UserInfo.getUserId(),
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 300,
            Target_Amount__c = 3000
        );
        insert awpt;

        Test.startTest();
        String result = TargetModule.getProductTargetQtyByProdCatValAmt(product.Id, UserInfo.getUserId(), acc.Id, fy.Id);
        Test.stopTest();

    }
}