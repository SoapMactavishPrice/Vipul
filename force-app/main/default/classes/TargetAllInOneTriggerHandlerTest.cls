@isTest
public class TargetAllInOneTriggerHandlerTest {
    @isTest
    static void testRollupTargetAmountEmployeeWiseTarget() {
        Fiscal_Year__c fy = createFutureFiscalYear('FY 2025');

        Employee_Wise_Target__c target = new Employee_Wise_Target__c(
            Employee__c = UserInfo.getUserId(),
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 10,
            Target_Amount__c = 1000
        );
        insert target;

        List<sObject> newRecords = new List<sObject>{target};
        Map<Id, sObject> oldMap = new Map<Id, sObject>{
            target.Id => new Employee_Wise_Target__c(
                Id = target.Id,
                Target_Quantity__c = 100,
                Target_Amount__c = 10000
            )
        };

        Test.startTest();
        TargetAllInOneTriggerHandler.rollupTargetAmount(newRecords, oldMap, 'EmployeeWiseTarget');
        Test.stopTest();
    }

    @isTest
    static void testRollupTargetAmountEmployeeWiseProductTarget() {
        Fiscal_Year__c fy = createFutureFiscalYear('FY 2024');

        Product2 prod = new Product2();
        prod.Name = 'VOXCO ZINC PHOSPHATE';
        prod.Family = 'Anti-Corrosive';
        insert prod;

        Employee_Wise_Product_Target__c productTarget = new Employee_Wise_Product_Target__c(
            Employee__c = UserInfo.getUserId(),
            Product__c = prod.Id,
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 100,
            Target_Amount__c = 1200
        );
        insert productTarget;

        List<sObject> newRecords = new List<sObject>{productTarget};
        Map<Id, sObject> oldMap = new Map<Id, sObject>{
            productTarget.Id => new Employee_Wise_Product_Target__c(
                Id = productTarget.Id,
                Target_Quantity__c = 100,
                Target_Amount__c = 1000
            )
        };

        Test.startTest();
        TargetAllInOneTriggerHandler.rollupTargetAmount(newRecords, oldMap, 'EmployeeWiseProductTarget');
        Test.stopTest();
    }

    @isTest
    static void createMonthlyTargetEntriesTest() {
        Fiscal_Year__c fy = createFutureFiscalYear('FY 2024');

        Account acc = new Account(Name = 'Account');
        insert acc;

        Employee_Wise_Account_Target__c accountTarget = new Employee_Wise_Account_Target__c(
            Employee__c = UserInfo.getUserId(),
            Account__c = acc.Id,
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 100,
            Target_Amount__c = 1200
        );
        insert accountTarget;

        List<sObject> newRecords = new List<sObject>{accountTarget};
        Map<Id, sObject> oldMap = new Map<Id, sObject>{
            accountTarget.Id => new Employee_Wise_Account_Target__c(
                Id = accountTarget.Id,
                Target_Quantity__c = 100,
                Target_Amount__c = 1000
            )
        };

        Test.startTest();
        TargetAllInOneTriggerHandler.createMonthlyTargetEntries(newRecords);
        Test.stopTest();
    }

    @isTest
    static void updateMonthlyTargetEntriesTest() {
        Fiscal_Year__c fy = createFutureFiscalYear('FY 2024');

        Employee_Wise_Target__c target = new Employee_Wise_Target__c(
            Employee__c = UserInfo.getUserId(),
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 10,
            Target_Amount__c = 1000
        );
        insert target;

        List<sObject> newRecords = new List<sObject>{target};
        Map<Id, sObject> newMap = new Map<Id, sObject>(newRecords);
        Map<Id, sObject> oldMap = new Map<Id, sObject>{
            target.Id => new Employee_Wise_Target__c(
                Id = target.Id,
                Target_Quantity__c = 100,
                Target_Amount__c = 10000
            )
        };

        Test.startTest();
        TargetAllInOneTriggerHandler.updateMonthlyTargetEntries(newRecords, oldMap, newMap, 'EmployeeWiseTarget');
        Test.stopTest();
    }

    @isTest
    static void updateMonthlyAccountTargetEntriesTest() {
        Fiscal_Year__c fy = createFutureFiscalYear('FY 2024');

        Account acc = new Account(Name = 'Account');
        insert acc;

        Employee_Wise_Account_Target__c target = new Employee_Wise_Account_Target__c(
            Account__c = acc.Id,
            Employee__c = UserInfo.getUserId(),
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 10,
            Target_Amount__c = 1000
        );
        insert target;

        List<sObject> newRecords = new List<sObject>{target};
        Map<Id, sObject> newMap = new Map<Id, sObject>(newRecords);
        Map<Id, sObject> oldMap = new Map<Id, sObject>{
            target.Id => new Employee_Wise_Account_Target__c(
                Id = target.Id,
                Target_Quantity__c = 100,
                Target_Amount__c = 10000
            )
        };

        Test.startTest();
        TargetAllInOneTriggerHandler.updateMonthlyTargetEntries(newRecords, oldMap, newMap, 'EmployeeWiseAccountTarget');
        Test.stopTest();
    }

    @isTest
    static void updateEmployeeWiseAccountTargetAllowsNullTargetsOnUpdate() {
        Date fiscalStartDate = Date.today().toStartOfMonth().addMonths(1);
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = 'FY Future',
            FY_Start_Date__c = fiscalStartDate,
            FY_End_Date__c = fiscalStartDate.addMonths(12).addDays(-1)
        );
        insert fy;

        Account acc = new Account(Name = 'Future Account');
        insert acc;

        Employee_Wise_Account_Target__c target = new Employee_Wise_Account_Target__c(
            Account__c = acc.Id,
            Employee__c = UserInfo.getUserId(),
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 120,
            Target_Amount__c = 1200
        );
        insert target;

        Employee_Wise_Account_Target__c insertedTarget = [
            SELECT Id, Target_Quantity__c, Target_Amount__c,
                (
                    SELECT Id, Monthly_Target_Quantity__c, Monthly_Target_Amount__c
                    FROM Employee_Wise_Account_Target_Line_Item__r
                    ORDER BY Start_Date__c
                )
            FROM Employee_Wise_Account_Target__c
            WHERE Id = :target.Id
        ];

        target.Target_Quantity__c = null;
        target.Target_Amount__c = null;

        Test.startTest();
        update target;
        Test.stopTest();

        Employee_Wise_Account_Target__c updatedTarget = [
            SELECT Id, Target_Quantity__c, Target_Amount__c,
                (
                    SELECT Id, Monthly_Target_Quantity__c, Monthly_Target_Amount__c
                    FROM Employee_Wise_Account_Target_Line_Item__r
                    ORDER BY Start_Date__c
                )
            FROM Employee_Wise_Account_Target__c
            WHERE Id = :target.Id
        ];
    }

    @isTest
    static void shareRecordWithUserTest() {
        List<Employee_Wise_Target__c> employeeTargets = new List<Employee_Wise_Target__c>();
        List<Employee_Wise_Product_Target__c> productTargets = new List<Employee_Wise_Product_Target__c>();
        List<Employee_Wise_Account_Target__c> accountTargets = new List<Employee_Wise_Account_Target__c>();

        Fiscal_Year__c fy = createFutureFiscalYear('FY 2024');

        Product2 prod = new Product2();
        prod.Name = 'VOXCO ZINC PHOSPHATE';
        prod.Family = 'Anti-Corrosive';
        insert prod;

        Employee_Wise_Target__c ewt = new Employee_Wise_Target__c(
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 100,
            Target_Amount__c = 1000,
            Employee__c = UserInfo.getUserId()
        );
        employeeTargets.add(ewt);

        Employee_Wise_Product_Target__c ewpt = new Employee_Wise_Product_Target__c(
            Fiscal_Year__c = fy.Id,
            Product__c = prod.Id,
            Target_Quantity__c = 200,
            Target_Amount__c = 2000,
            Employee__c = UserInfo.getUserId()
        );
        productTargets.add(ewpt);

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Employee_Wise_Account_Target__c ewat = new Employee_Wise_Account_Target__c(
            Fiscal_Year__c = fy.Id,
            Account__c = acc.Id,
            Target_Quantity__c = 300,
            Target_Amount__c = 3000,
            Employee__c = UserInfo.getUserId()
        );
        accountTargets.add(ewat);

        insert employeeTargets;
        insert productTargets;
        insert accountTargets;

        List<sObject> newRecords = new List<sObject>();
        newRecords.addAll(employeeTargets);
        newRecords.addAll(productTargets);
        newRecords.addAll(accountTargets);

        Test.startTest();
        TargetAllInOneTriggerHandler.shareRecordWithUser(newRecords, null);
        Test.stopTest();
    }

    @isTest
    static void testAccountWiseProductTargetTrigger() {
        Fiscal_Year__c fy = createFutureFiscalYear('FY 2024');

        Account_Wise_Product_Target__c awpt = new Account_Wise_Product_Target__c(
            Employee__c = UserInfo.getUserId(),
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 100,
            Target_Amount__c = 1200
        );
        insert awpt;

        Account_Wise_Product_Target_Line_Item__c awptLineItem = new Account_Wise_Product_Target_Line_Item__c(
            Account_Wise_Product_Target__c = awpt.Id
        );

        Test.startTest();
        insert awptLineItem;
        Test.stopTest();
    }

    @isTest
    static void testAccountWiseProductTargetLineItemTrigger() {
        Fiscal_Year__c fy = createFutureFiscalYear('FY 2024');

        Account_Wise_Product_Target__c awpt = new Account_Wise_Product_Target__c(
            Employee__c = UserInfo.getUserId(),
            Fiscal_Year__c = fy.Id,
            Target_Quantity__c = 100,
            Target_Amount__c = 1200
        );
        insert awpt;

        Account_Wise_Product_Target_Line_Item__c awptLineItem = new Account_Wise_Product_Target_Line_Item__c(
            Account_Wise_Product_Target__c = awpt.Id
        );

        Test.startTest();
        insert awptLineItem;
        Test.stopTest();
    }

    private static Fiscal_Year__c createFutureFiscalYear(String name) {
        Date fiscalStartDate = Date.today().toStartOfMonth().addMonths(1);
        Fiscal_Year__c fy = new Fiscal_Year__c(
            Name = name,
            FY_Start_Date__c = fiscalStartDate,
            FY_End_Date__c = fiscalStartDate.addMonths(12).addDays(-1)
        );
        insert fy;
        return fy;
    }
}
