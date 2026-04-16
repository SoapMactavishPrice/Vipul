@isTest
public class targetvsactualChildControllerTest {

    @testSetup
    static void setupData() {
        // Create Fiscal Year recor
        Fiscal_Year__c fisc = new Fiscal_Year__c(Name = '2025-2026', FY_Start_Date__c = Date.newInstance(2025, 4, 1), FY_End_Date__c = Date.newInstance(2026, 3, 31));
        insert fisc;

        // Create Employee (User) record
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User employee = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testusesdawwar@example.com' + System.currentTimeMillis(),
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert employee;

        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', Family = 'Test Family', isActive = true);
        insert prod;

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // ---------- EMPLOYEE WISE TARGET ----------
        Employee_Wise_Target__c empTarget = new Employee_Wise_Target__c(
            Fiscal_Year__c = fisc.Id,
            Employee__c = employee.Id
            
        );
        insert empTarget;

        Employee_Wise_Target_Line_Item__c ewLine = new Employee_Wise_Target_Line_Item__c(
            Employee_Wise_Target__c = empTarget.Id,
            Month_Name__c = 'January',
            Start_Date__c = Date.today(),
            Monthly_Target_Amount__c = 1000,
            Monthly_Target_Quantity__c = 10,
            Actual_Quantity__c = 5,
           // Pending_Quantity__c = 5,
            Actual_Amount__c = 500
            //Pending_Amount__c = 500
        );
        insert ewLine;


        Employee_Wise_Product_Target__c ewpt = new Employee_Wise_Product_Target__c(
            Fiscal_Year__c = fisc.Id,
            Employee__c = employee.Id,
            Product__c = prod.Id
        );
        insert ewpt;

        Employee_Wise_Product_Target_Line_Item__c ewptLine = new Employee_Wise_Product_Target_Line_Item__c(
            Employee_Wise_Product_Target__c = ewpt.Id,
            Start_Date__c = Date.today(),
            Monthly_Target_Amount__c = 2000
        );
        insert ewptLine;

        // ---------- EMPLOYEE WISE ACCOUNT TARGET ----------
        Employee_Wise_Account_Target__c ewat = new Employee_Wise_Account_Target__c(
            Fiscal_Year__c = fisc.Id,
            Employee__c = employee.Id,
            Account__c = acc.Id
        );
        insert ewat;

        Employee_Wise_Account_Target_Line_Item__c ewatLine = new Employee_Wise_Account_Target_Line_Item__c(
            Employee_Wise_Account_Target__c = ewat.Id,
            Start_Date__c = Date.today(),
            Monthly_Target_Amount__c = 3000
        );
        insert ewatLine;

        // ---------- ACCOUNT WISE PRODUCT TARGET ----------
        Account_Wise_Product_Target__c awpt = new Account_Wise_Product_Target__c(
            Fiscal_Year__c = fisc.Id,
            Employee__c = employee.Id,
            Account__c = acc.Id,
            Product__c = prod.Id
        );
        insert awpt;

        Account_Wise_Product_Target_Line_Item__c awptLine = new Account_Wise_Product_Target_Line_Item__c(
            Account_Wise_Product_Target__c = awpt.Id,
            Start_Date__c = Date.today(),
            Monthly_Target_Amount__c = 4000
        );
        insert awptLine;
    }

    @isTest
    static void testGetYearlyForEmployeeWiseTarget() {
        User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Fiscal_Year__c fisc = [SELECT Id FROM Fiscal_Year__c LIMIT 1];
        String result = targetvsactualChildController.getYearly(null, fisc.Id, u.Id, 'Employee_Wise_Target__c', null, null);
       
    }

    @isTest
    static void testGetYearlyForEmployeeWiseProductTarget() {
        User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Fiscal_Year__c fisc = [SELECT Id FROM Fiscal_Year__c LIMIT 1];
        String result = targetvsactualChildController.getYearly(null, fisc.Id, u.Id, 'Employee_Wise_Product_Target__c', null, null);
        
    }

    @isTest
    static void testGetYearlyForEmployeeWiseAccountTarget() {
        User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Fiscal_Year__c fisc = [SELECT Id FROM Fiscal_Year__c LIMIT 1];
        String result = targetvsactualChildController.getYearly(null, fisc.Id, u.Id, 'Employee_Wise_Account_Target__c', null, null);
        
    }

    @isTest
    static void testGetYearlyForAccountWiseProductTarget() {
        User u = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        Fiscal_Year__c fisc = [SELECT Id FROM Fiscal_Year__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        String result = targetvsactualChildController.getYearly(null, fisc.Id, u.Id, 'Account_Wise_Product_Target__c', null, acc.Id);
       
    }
    
    @isTest
    static void testGetMonthly_EmpWiseTarget() {
        String result = targetvsactualChildController.getMonthly(
            [SELECT Id FROM Fiscal_Year__c LIMIT 1].Id,
            null,
            'Employee_Wise_Target__c',
            null
        );
    }

    @isTest
    static void testGetMonthly_EmpWiseProdTarget() {
        String result = targetvsactualChildController.getMonthly(
            [SELECT Id FROM Fiscal_Year__c LIMIT 1].Id,
            [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1].Id,
            'Employee_Wise_Product_Target__c',
            null
        );
    }

    @isTest
    static void testGetMonthly_EmpWiseAccountTarget() {
        String result = targetvsactualChildController.getMonthly(
            [SELECT Id FROM Fiscal_Year__c LIMIT 1].Id,
            [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1].Id,
            'Employee_Wise_Account_Target__c',
            null
        );
    }

    @isTest
    static void testGetMonthly_AccWiseProdTarget() {
        String result = targetvsactualChildController.getMonthly(
            [SELECT Id FROM Fiscal_Year__c LIMIT 1].Id,
            [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1].Id,
            'Account_Wise_Product_Target__c',
            [SELECT Id FROM Account LIMIT 1].Id
        );
    }

    @isTest
    static void testGetMonthly_BlankParams() {
        String result = targetvsactualChildController.getMonthly(null, null, null, null);
    }
}