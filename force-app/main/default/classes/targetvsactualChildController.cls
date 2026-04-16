public with sharing class targetvsactualChildController {
    public targetvsactualChildController() {

    }

    @AuraEnabled
    public static string getYearly(String prodId, String fiscId, String empId, String parentTab, String prodCatVal, String accId) {
        try {
            system.debug('prodId' + prodId);
            system.debug('fiscId' + fiscId);
            system.debug('empId' + empId);
            system.debug('parentTab' + parentTab);

            if (String.isBlank(fiscId) || String.isBlank(parentTab)) {
                return '{}';
            }

            Boolean isComplete = [select is_Complete__c from Fiscal_Year__c where Id =: fiscId].is_Complete__c;

            Map < String, Object > result = new Map < String, Object > ();
            List < Map < String, Object >> parameterData = new List < Map < String, Object >> ();

            Set < String > masterRecordIds = new Set < String > ();
            Integer index = 0;

            String queryFront = '';
            String whr = '';
            String ordBy = ' ORDER BY Name ASC ';

            whr += ' WHERE Fiscal_Year__c = \'' + fiscId + '\' ';
            System.debug(whr);
            system.debug(parentTab + ' ' + masterRecordIds);
            switch on parentTab {
                when 'Employee_Wise_Target__c' {
                    queryFront = 'SELECT Id, Employee__c, Employee__r.Name, ' +
                        'Fiscal_Year__c, Fiscal_Year__r.Name, Fiscal_Year__r.isActive__c, Fiscal_Year__r.is_Complete__c, Fiscal_Year__r.Is_Planning__c, ' +
                        'Target_Quantity__c, Target_Amount_Monthly_Rollup__c, ' +
                        'Target_Quantity_Monthly__c, Actual_Amount__c, ' +
                        'Actual_Quantity__c, Pending_Amount__c, ' +
                        'Pending_Quantity__c ' +
                        'FROM ' + parentTab + ' ';

                    whr += ' AND Employee__c IN: masterRecordIds ';

            //        String userQuery = 'SELECT Id, Name, isActive FROM User WHERE isActive = TRUE AND Profile.UserLicense.Name = \'Salesforce\' ORDER BY Name ASC';

                     // Check if current user is System Administrator
                    Boolean isSystemAdmin = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name == 'System Administrator';
                    
                    String userQuery;
                    if (isSystemAdmin) {
                        // Show all active users for System Admin
                        userQuery = 'SELECT Id, Name, isActive FROM User WHERE isActive = TRUE AND Profile.UserLicense.Name = \'Salesforce\' ORDER BY Name ASC';
                    } else {
                        // Show only current user for non-admin users
                        userQuery = 'SELECT Id, Name, isActive FROM User WHERE Id = \'' + UserInfo.getUserId() + '\' AND isActive = TRUE';
                    }
                    
                    List < User > users = Database.query(userQuery);
                    System.debug(users.size());
                    if (users.size() == 0) {
                        return '{}';
                    }

                    for (User u: users) {
                        Map < String, Object > tempMap = new Map < String, Object > ();
                        tempMap.put('ParameterId', u.Id);
                        tempMap.put('ParameterName', u.Name);
                        tempMap.put('ParameterEdit', false);
                        tempMap.put('Target_Quantity__c', null);
                        tempMap.put('Target_Quantity_Monthly__c', null);
                        tempMap.put('Actual_Quantity__c', null);
                        tempMap.put('Pending_Quantity__c', null);
                        tempMap.put('Target_Amount_Monthly_Rollup__c', null);
                        tempMap.put('Actual_Amount__c', null);
                        tempMap.put('Pending_Amount__c', null);
                        tempMap.put('targetAmountEdit', !isComplete);

                        parameterData.add(tempMap);
                        masterRecordIds.add(u.Id);
                    }
                }

                when 'Employee_Wise_Product_Target__c' {
                    queryFront = 'SELECT Id, Name, Product__c, Product__r.Name, Employee__c,' +
                        'Fiscal_Year__c, Fiscal_Year__r.Name, Fiscal_Year__r.isActive__c, Fiscal_Year__r.is_Complete__c, Fiscal_Year__r.Is_Planning__c, ' +
                        'Target_Quantity__c, Target_Amount_Monthly_Rollup__c,' +
                        'Monthly_Target_Quantity__c, Actual_Amount__c, ' +
                        'Actual_Quantity__c, Pending_Amount__c, ' +
                        'Pending_Quantity__c ' +
                        'FROM ' + parentTab + ' ';

                    whr += ' AND Employee__c =: empId ';

                    String ProductQuery = 'SELECT Id, Name, Family from Product2 order by Name ASC';
                    List < Product2 > Product = Database.query(ProductQuery);
                    system.debug('Product' + Product.size());
                    system.debug('Product' + Product);

                    if (Product.size() == 0) {
                        return JSON.serialize(parameterData);
                    }

                    Schema.DescribeFieldResult fieldResult = Employee_Wise_Product_Target__c.Product__c.getDescribe();
                    List < Schema.PicklistEntry > ple = fieldResult.getPicklistValues();
                    for (Product2 p: Product) {
                        Map < String, Object > tempMap = new Map < String, Object > ();
                        tempMap.put('ParameterId', p.Id);
                        tempMap.put('ParameterName', p.Name);
                        tempMap.put('ParameterEdit', false);
                        tempMap.put('Target_Quantity__c', null);
                        tempMap.put('Target_Quantity_Monthly__c', null);
                        tempMap.put('Actual_Quantity__c', null);
                        tempMap.put('Pending_Quantity__c', null);
                        tempMap.put('Target_Amount_Monthly_Rollup__c', null);
                        tempMap.put('Actual_Amount__c', null);
                        tempMap.put('Pending_Amount__c', null);
                        tempMap.put('targetAmountEdit', !isComplete);
                        masterRecordIds.add(p.Id);
                        parameterData.add(tempMap);
                    }
                }

                when 'Employee_Wise_Account_Target__c' {
                    queryFront = 'SELECT Id, Name, Employee__c, Account__c, Account__r.Name, ' +
                        'Fiscal_Year__c, Fiscal_Year__r.Name, Fiscal_Year__r.isActive__c, Fiscal_Year__r.is_Complete__c, Fiscal_Year__r.Is_Planning__c, ' +
                        'Target_Quantity__c, ' +
                        'Monthly_Target_Quantity__c, Actual_Amount__c, ' +
                        'Actual_Quantity__c, Pending_Amount__c, Target_Amount_Monthly_Rollup__c,' +
                        'Pending_Quantity__c ' +
                        'FROM ' + parentTab + ' ';

                    whr += ' AND Employee__c =: empId ';

             //       String AccountQuery = 'SELECT Id, Name from Account order by Name ASC';
                   
                     // Get current user and profile
                    String currentUserId = UserInfo.getUserId();
                    User currentUser = [SELECT Profile.Name FROM User WHERE Id = :currentUserId];
                    String profileName = currentUser.Profile.Name;
                    
                    // Control access
                    Boolean isSystemAdmin = (profileName == 'System Administrator');
                    
                    // If not admin and trying to access data of another user, exit early
                    if (!isSystemAdmin && empId != currentUserId) {
                        System.debug('Non-admin user tried to access data for another user. Access denied.');
                        return JSON.serialize(parameterData);
                    }
                    
                    // Prepare Account query
                    String AccountQuery = 'SELECT Id, Name FROM Account WHERE OwnerId = :empId ORDER BY Name ASC';
                    
                    
                    List < Account > Account = Database.query(AccountQuery);
                    system.debug('Account' + Account.size());
                    system.debug('Account' + Account);

                    if (Account.size() == 0) {
                        return JSON.serialize(parameterData);
                    }

                    Schema.DescribeFieldResult fieldResult = Employee_Wise_Account_Target__c.Account__c.getDescribe();
                    List < Schema.PicklistEntry > ple = fieldResult.getPicklistValues();
                    for (Account p: Account) {
                        Map < String, Object > tempMap = new Map < String, Object > ();
                        tempMap.put('ParameterId', p.Id);
                        tempMap.put('ParameterName', p.Name);
                        tempMap.put('ParameterEdit', false);
                        tempMap.put('Target_Quantity__c', null);
                        tempMap.put('Target_Quantity_Monthly__c', null);
                        tempMap.put('Actual_Quantity__c', null);
                        tempMap.put('Pending_Quantity__c', null);
                        tempMap.put('Target_Amount_Monthly_Rollup__c', null);
                        tempMap.put('Actual_Amount__c', null);
                        tempMap.put('Pending_Amount__c', null);
                        tempMap.put('targetAmountEdit', !isComplete);
                        masterRecordIds.add(p.Id);
                        parameterData.add(tempMap);
                    }
                }
                
               when 'Account_Wise_Product_Target__c' {
    queryFront = 'SELECT Id, Name, Product__c, Product__r.Name, Product__r.ProductCode, Product__r.Description, Employee__c, Employee__r.Name, Account__c, Account__r.Name,' +
        'Fiscal_Year__c, Fiscal_Year__r.Name, Fiscal_Year__r.isActive__c, Fiscal_Year__r.is_Complete__c, Fiscal_Year__r.Is_Planning__c, ' +
        'Target_Quantity__c, Target_Amount__c, ' +
        'Monthly_Target_Quantity__c,Target_Amount_Monthly_Rollup__c,Actual_Amount__c, Actual_Quantity__c,Pending_Amount__c, Pending_Quantity__c ' +
        'FROM ' + parentTab + ' ';

  //  whr += ' AND Account__c = \'' + accId + '\' ';
  //  whr += ' AND Employee__c = \'' + empId + '\' ';

 //   String ProductQuery = 'SELECT Id, Name, ProductCode, Description from Product2 order by Name ASC';
                   
                    // Get current user info
                    String currentUserId = UserInfo.getUserId();
                    User currentUser = [SELECT Profile.Name FROM User WHERE Id = :currentUserId];
                    String profileName = currentUser.Profile.Name;
                    Boolean isSystemAdmin = (profileName == 'System Administrator');
                    
                    //  Non-admins cannot view other employees' data
                    if (!isSystemAdmin && empId != currentUserId) {
                        System.debug('Access denied: Non-admin selected another employee.');
                        return JSON.serialize(parameterData);
                    }
                    
                    //  Non-admins: Verify selected account was created by current user
                    if (!isSystemAdmin) {
                        List<Account> validAccounts = [
                            SELECT Id FROM Account WHERE OwnerId = :currentUserId AND Id = :accId
                        ];
                        if (validAccounts.isEmpty()) {
                            System.debug('Access denied: Selected account not created by current user.');
                            return JSON.serialize(parameterData);
                        }
                    }
                    
                    //  Filters
                    whr += ' AND Account__c = :accId ';
                    whr += ' AND Employee__c = :empId ';
                    
                    // Product list
                    String ProductQuery = 'SELECT Id, Name, ProductCode, Description FROM Product2 ORDER BY Name ASC';
                   
                   List<Product2> Product = Database.query(ProductQuery);
                   system.debug('Product' + Product.size());
                   system.debug('Product' + Product);

    if (Product.size() == 0) {
        return JSON.serialize(parameterData);
    }

    for (Product2 p: Product) {
        Map<String, Object> tempMap = new Map<String, Object>();
        tempMap.put('ParameterId', p.Id);
        tempMap.put('ParameterName', p.Name);
        tempMap.put('ParameterCode', p.ProductCode);
        tempMap.put('ParameterDesc', p.Description);
        tempMap.put('ParameterEdit', false);
        tempMap.put('Target_Quantity__c', null);
        tempMap.put('Monthly_Target_Quantity__c', null);
        tempMap.put('Actual_Quantity__c', null);
        tempMap.put('Pending_Quantity__c', null);
        tempMap.put('Target_Amount_Monthly_Rollup__c', null);
        tempMap.put('Target_Amount__c', null);
        tempMap.put('Target_Amount_New__c', null);
        tempMap.put('targetAmountEdit', !isComplete);
        masterRecordIds.add(p.Id);
        parameterData.add(tempMap);
    }
}
            }

            String query = queryFront + whr + ordBy;
            System.debug('masterRecordIds:>> ' + masterRecordIds);
            System.debug('query:>> ' + query);

            for (sObject record: Database.query(query)) {
                System.debug(record);
                Map < String, Object > tempMap = new Map < String, Object > ();
                tempMap.put('Id', record.Id);
                switch on parentTab {
                    when 'Employee_Wise_Target__c' {
                        Employee_Wise_Target__c rec = (Employee_Wise_Target__c) record;
                        tempMap.put('ParameterId', rec.Employee__c);
                        tempMap.put('ParameterName', rec.Employee__r.Name);
                        tempMap.put('ParameterEdit', false);
                        tempMap.put('Target_Quantity__c', rec.Target_Quantity__c != null ? rec.Target_Quantity__c.setScale(2) : null);
                        tempMap.put('Target_Quantity_Monthly__c', rec.Target_Quantity_Monthly__c != null ? rec.Target_Quantity_Monthly__c.setScale(2) : null);
                        tempMap.put('Actual_Quantity__c', rec.Actual_Quantity__c != null ? rec.Actual_Quantity__c.setScale(2) : null);
                        tempMap.put('Pending_Quantity__c', rec.Pending_Quantity__c != null ? rec.Pending_Quantity__c.setScale(2) : null);
                        tempMap.put('Target_Amount_Monthly_Rollup__c', rec.Target_Amount_Monthly_Rollup__c != null ? rec.Target_Amount_Monthly_Rollup__c.setScale(2) : null);
                        tempMap.put('Actual_Amount__c', rec.Actual_Amount__c != null ? rec.Actual_Amount__c.setScale(2) : null);
                        tempMap.put('Pending_Amount__c', rec.Pending_Amount__c != null ? rec.Pending_Amount__c.setScale(2) : null);
                        tempMap.put('targetAmountEdit', !isComplete);

                        for (Integer j = 0; j < parameterData.size(); j++) {
                            Map < String, Object > empData = (Map < String, Object > ) parameterData[j];
                            if (tempMap.get('ParameterId') == empData.get('ParameterId')) {
                                parameterData[j] = tempMap;
                                break;
                            }
                        }
                    }

                    when 'Employee_Wise_Product_Target__c' {
                        Employee_Wise_Product_Target__c rec = (Employee_Wise_Product_Target__c) record;
                        tempMap.put('ParameterId', rec.Product__c);
                        tempMap.put('ParameterName', rec.Product__r.Name);
                        tempMap.put('ParameterEdit', false);
                        tempMap.put('Target_Quantity__c', rec.Target_Quantity__c != null ? rec.Target_Quantity__c.setScale(2) : null);
                        tempMap.put('Target_Quantity_Monthly__c', rec.Monthly_Target_Quantity__c != null ? rec.Monthly_Target_Quantity__c.setScale(2) : null);
                        tempMap.put('Actual_Quantity__c', rec.Actual_Quantity__c != null ? rec.Actual_Quantity__c.setScale(2) : null);
                        tempMap.put('Pending_Quantity__c', rec.Pending_Quantity__c != null ? rec.Pending_Quantity__c.setScale(2) : null);
                        tempMap.put('Target_Amount_Monthly_Rollup__c', rec.Target_Amount_Monthly_Rollup__c != null ? rec.Target_Amount_Monthly_Rollup__c.setScale(2) : null);
                        tempMap.put('Actual_Amount__c', rec.Actual_Amount__c != null ? rec.Actual_Amount__c.setScale(2) : null);
                        tempMap.put('Pending_Amount__c', rec.Pending_Amount__c != null ? rec.Pending_Amount__c.setScale(2) : null);
                        tempMap.put('targetAmountEdit', !isComplete);

                        for (Integer j = 0; j < parameterData.size(); j++) {
                            Map < String, Object > empData = (Map < String, Object > ) parameterData[j];
                            if (tempMap.get('ParameterId') == empData.get('ParameterId')) {
                                parameterData[j] = tempMap;
                                break;
                            }
                        }
                    }

                    when 'Employee_Wise_Account_Target__c' {
                        Employee_Wise_Account_Target__c rec = (Employee_Wise_Account_Target__c) record;
                        tempMap.put('ParameterId', rec.Account__c);
                        tempMap.put('ParameterName', rec.Account__r.Name);
                        tempMap.put('ParameterEdit', false);
                        tempMap.put('Target_Quantity__c', rec.Target_Quantity__c != null ? rec.Target_Quantity__c.setScale(2) : null);
                        tempMap.put('Target_Quantity_Monthly__c', rec.Monthly_Target_Quantity__c != null ? rec.Monthly_Target_Quantity__c.setScale(2) : null);
                        tempMap.put('Actual_Quantity__c', rec.Actual_Quantity__c != null ? rec.Actual_Quantity__c.setScale(2) : null);
                        tempMap.put('Pending_Quantity__c', rec.Pending_Quantity__c != null ? rec.Pending_Quantity__c.setScale(2) : null);
                        tempMap.put('Target_Amount_Monthly_Rollup__c', rec.Target_Amount_Monthly_Rollup__c != null ? rec.Target_Amount_Monthly_Rollup__c.setScale(2) : null);
                        tempMap.put('Actual_Amount__c', rec.Actual_Amount__c != null ? rec.Actual_Amount__c.setScale(2) : null);
                        tempMap.put('Pending_Amount__c', rec.Pending_Amount__c != null ? rec.Pending_Amount__c.setScale(2) : null);
                        tempMap.put('targetAmountEdit', !isComplete);

                        for (Integer j = 0; j < parameterData.size(); j++) {
                            Map < String, Object > empData = (Map < String, Object > ) parameterData[j];
                            System.debug('check:>> ' + tempMap.get('ParameterId') + ' || ' + empData.get('ParameterId'));
                            if (tempMap.get('ParameterId') == empData.get('ParameterId')) {
                                parameterData[j] = tempMap;
                                break;
                            }
                        }
                    }
                    
                    when 'Account_Wise_Product_Target__c' {
    Account_Wise_Product_Target__c rec = (Account_Wise_Product_Target__c) record;
    tempMap.put('ParameterId', rec.Product__c);
    tempMap.put('ParameterName', rec.Product__r.Name);
    tempMap.put('ParameterCode', rec.Product__r.ProductCode);
    tempMap.put('ParameterDesc', rec.Product__r.Description);
    tempMap.put('AccountId', rec.Account__c);
    tempMap.put('AccountName', rec.Account__r.Name);
    tempMap.put('EmployeeId', rec.Employee__c);
    tempMap.put('EmployeeName', rec.Employee__r.Name);
    tempMap.put('ParameterEdit', false);
    tempMap.put('Target_Quantity__c', rec.Target_Quantity__c != null ? rec.Target_Quantity__c.setScale(2) : null);
    tempMap.put('Monthly_Target_Quantity__c', rec.Monthly_Target_Quantity__c != null ? rec.Monthly_Target_Quantity__c.setScale(2) : null);
    tempMap.put('Actual_Quantity__c', rec.Actual_Quantity__c != null ? rec.Actual_Quantity__c.setScale(2) : null);
    tempMap.put('Pending_Quantity__c', rec.Pending_Quantity__c != null ? rec.Pending_Quantity__c.setScale(2) : null);
    tempMap.put('Target_Amount_Monthly_Rollup__c', rec.Target_Amount_Monthly_Rollup__c != null ? rec.Target_Amount_Monthly_Rollup__c.setScale(2) : null);
    tempMap.put('Actual_Amount__c', rec.Actual_Amount__c != null ? rec.Actual_Amount__c.setScale(2) : null);
    tempMap.put('Pending_Amount__c', rec.Pending_Amount__c != null ? rec.Pending_Amount__c.setScale(2) : null);
    tempMap.put('targetAmountEdit', !isComplete);
    
    if(rec.Target_Amount__c == null){
        tempMap.put('Target_Amount__c', '');
        tempMap.put('Target_Amount_New__c', '');
    } else {
        tempMap.put('Target_Amount__c', rec.Target_Amount__c.setScale(2));
        tempMap.put('Target_Amount_New__c', rec.Target_Amount__c.setScale(2));
    }

    if (rec.Fiscal_Year__r.Is_Planning__c || rec.Fiscal_Year__r.isActive__c) {
        tempMap.put('targetAmountEdit', true);
    } else if (rec.Fiscal_Year__r.is_Complete__c) {
        tempMap.put('targetAmountEdit', false);
    }

    for (Integer j = 0; j < parameterData.size(); j++) {
        Map<String, Object> empData = (Map<String, Object>) parameterData[j];
        if (tempMap.get('ParameterId') == empData.get('ParameterId')) {
            parameterData[j] = tempMap;
            break;
        }
    }
}
                }

                System.debug(parameterData.size());
                System.debug('---------------------------------------------------------------------------');
                index++;
            }

            result.put('parameterData', parameterData);
            return JSON.serialize(result);

        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }

    @AuraEnabled
    public static string getMonthly(String fiscId, String empId, String parentTab, String accId) {
        try {
            if (String.isBlank(fiscId) || String.isBlank(parentTab)) {
                return '{}';
            }
            
             // Handle empty cases for specific tabs
        if (parentTab == 'Employee_Wise_Account_Target__c' && String.isBlank(empId)) {
            return '{"months":[],"parameterData":[]}';
        }
        if (parentTab == 'Account_Wise_Product_Target__c' && String.isBlank(accId)) {
            return '{"months":[],"parameterData":[]}';
        }
        
        // Get current user info
        Boolean isSystemAdmin = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name == 'System Administrator';

            Map < String, Object > result = new Map < String, Object > ();

            List < String > months = new List < String > ();
            for (sObject res: [SELECT Month_Name__c, Start_Date__c
                    FROM Employee_Wise_Target_Line_Item__c
                    WHERE Employee_Wise_Target__r.Fiscal_Year__c =: fiscId
                    GROUP BY Start_Date__c, Month_Name__c ORDER BY Start_Date__c
                ]) {
                months.add(String.valueOf(res.get('Month_Name__c')));
            }

            result.put('months', months);

            String queryFront = '';
            String whr = '';
            String ordBy = '';

            whr += ' WHERE Fiscal_Year__c = \'' + fiscId + '\' ';

            switch on parentTab {
                when 'Employee_Wise_Target__c' {
                    queryFront = 'SELECT Id, Employee__c, Employee__r.Name, Start_Date__c, ' +
                        '(SELECT Id, Start_Date__c, End_Date__c, Actual_Quantity__c, Actual_Amount__c, Pending_Quantity__c, Pending_Amount__c, Monthly_Target_Quantity__c, Monthly_Target_Amount__c FROM Employee_Wise_Target_Line_Items__r ORDER BY Start_Date__c) ' +
                        ' FROM ' + parentTab + ' ';
                    ordBy = ' ORDER BY Employee__r.Name ASC ';
                    
                    if (!isSystemAdmin) {
                    // For non-admin users, only show their own records
                    whr += ' AND Employee__c = \'' + UserInfo.getUserId() + '\' ';
                }
                }

                when 'Employee_Wise_Product_Target__c' {
                    queryFront = 'SELECT Id, Product__c, Product__r.Name, Start_Date__c, ' +
                        '(SELECT Id, Start_Date__c, End_Date__c, Actual_Quantity__c, Actual_Amount__c, Pending_Quantity__c, Pending_Amount__c, Monthly_Target_Quantity__c, Monthly_Target_Amount__c FROM Employee_Wise_Product_Target_Line_Items__r ORDER BY Start_Date__c) ' +
                        ' FROM ' + parentTab + ' ';
                    whr += ' AND Employee__c = \'' + empId + '\' ';
                    ordBy = ' ORDER BY Product__r.Name ASC ';
                }

                when 'Employee_Wise_Account_Target__c' {
                    queryFront = 'SELECT Id, Account__c, Account__r.Name, Start_Date__c, ' +
                        '(SELECT Id, Start_Date__c, End_Date__c, Actual_Quantity__c, Actual_Amount__c, Pending_Quantity__c, Pending_Amount__c, Monthly_Target_Quantity__c, Monthly_Target_Amount__c FROM Employee_Wise_Account_Target_Line_Item__r ORDER BY Start_Date__c) ' +
                        ' FROM ' + parentTab + ' ';
                 //   whr += ' AND Employee__c = \'' + empId + '\' ';
                
                     if (!isSystemAdmin) {
                    // For non-admin users, only show accounts they created
                    whr += ' AND Employee__c = \'' + UserInfo.getUserId() + '\' ';
                    whr += ' AND Account__c IN (SELECT Id FROM Account WHERE OwnerId = \'' + UserInfo.getUserId() + '\') ';
                } else {
                    // For admin users, filter by the provided empId if available
                    if (String.isNotBlank(empId)) {
                        whr += ' AND Employee__c = \'' + empId + '\' ';
                    }
                }
                    
                    ordBy = ' ORDER BY Account__r.Name ASC ';
                }
                
                when 'Account_Wise_Product_Target__c' {
                    queryFront = 'SELECT  Product__c,Employee__c,Employee__r.Name, Product_Code__c, Description__c, Product__r.Name, Product__r.ProductCode, Product__r.Description, Product__r.Family, Account__c, Account__r.Name, ' +
                                 '(SELECT Id, Start_Date__c, End_Date__c,Actual_Quantity__c,Actual_Amount__c,Pending_Quantity__c,Pending_Amount__c,Monthly_Target_Quantity__c, Monthly_Target_Amount__c ' +
                                 ' FROM Account_Wise_Product_Target_Line_Item__r ORDER BY Start_Date__c) ' +
                                 ' FROM ' + parentTab + ' ';
                    whr += ' AND Employee__c = \'' + empId + '\' ';
                    whr += ' AND Account__c = \'' + accId + '\' ';
                    ordBy = ' ORDER BY Product__r.Name ASC ';
                }
            }

            String query = queryFront + whr + ordBy;
            System.debug(query);
            for (sObject record: Database.query(query)) {
                Map < String, Object > tempMap = new Map < String, Object > ();
                tempMap.put('Id', record.Id);
                switch on parentTab {
                    when 'Employee_Wise_Target__c' {
                        Employee_Wise_Target__c rec = (Employee_Wise_Target__c) record;
                        tempMap.put('ParameterId', rec.Employee__c);
                        tempMap.put('ParameterName', rec.Employee__r.Name);

                        for (Employee_Wise_Target_Line_Item__c childRec: rec.Employee_Wise_Target_Line_Items__r) {
                            Map < String, Object > childMap = new Map < String, Object > ();
                            childMap.put('ParameterId', childRec.Id);
                            childMap.put('Monthly_Target_Quantity__c', childRec.Monthly_Target_Quantity__c != null ? childRec.Monthly_Target_Quantity__c.setScale(2) : null);
                            childMap.put('Monthly_Target_Amount__c', childRec.Monthly_Target_Amount__c != null ? childRec.Monthly_Target_Amount__c.setScale(2) : null);
                            childMap.put('Actual_Quantity__c', childRec.Actual_Quantity__c != null ? childRec.Actual_Quantity__c.setScale(2) : null);
                            childMap.put('Pending_Quantity__c', childRec.Pending_Quantity__c != null ? childRec.Pending_Quantity__c.setScale(2) : null);
                            childMap.put('Actual_Amount__c', childRec.Actual_Amount__c != null ? childRec.Actual_Amount__c.setScale(2) : null);
                            childMap.put('Pending_Amount__c', childRec.Pending_Amount__c != null ? childRec.Pending_Amount__c.setScale(2) : null);
                            childMap.put('targetAmountEdit', false);

                            if (tempMap.containsKey('childData')) {
                                List < Object > tempList = (List < object > ) tempMap.get('childData');
                                tempList.add(childMap);
                            } else {
                                tempMap.put('childData', new List < Object > {
                                    childMap
                                });
                            }
                        }
                    }

                    when 'Employee_Wise_Product_Target__c' {
                        Employee_Wise_Product_Target__c rec = (Employee_Wise_Product_Target__c) record;
                        tempMap.put('ParameterId', rec.Product__c);
                        tempMap.put('ParameterName', rec.Product__r.Name);

                        for (Employee_Wise_Product_Target_Line_Item__c childRec: rec.Employee_Wise_Product_Target_Line_Items__r) {
                            Map < String, Object > childMap = new Map < String, Object > ();
                            childMap.put('ParameterId', childRec.Id);
                            childMap.put('Monthly_Target_Quantity__c', childRec.Monthly_Target_Quantity__c != null ? childRec.Monthly_Target_Quantity__c.setScale(2) : null);
                            childMap.put('Monthly_Target_Amount__c', childRec.Monthly_Target_Amount__c != null ? childRec.Monthly_Target_Amount__c.setScale(2) : null);
                            childMap.put('Actual_Quantity__c', childRec.Actual_Quantity__c != null ? childRec.Actual_Quantity__c.setScale(2) : null);
                            childMap.put('Pending_Quantity__c', childRec.Pending_Quantity__c != null ? childRec.Pending_Quantity__c.setScale(2) : null);
                            childMap.put('Actual_Amount__c', childRec.Actual_Amount__c != null ? childRec.Actual_Amount__c.setScale(2) : null);
                            childMap.put('Pending_Amount__c', childRec.Pending_Amount__c != null ? childRec.Pending_Amount__c.setScale(2) : null);
                            childMap.put('targetAmountEdit', false);

                            if (tempMap.containsKey('childData')) {
                                List < Object > tempList = (List < object > ) tempMap.get('childData');
                                tempList.add(childMap);
                            } else {
                                tempMap.put('childData', new List < Object > {
                                    childMap
                                });
                            }
                        }
                    }

                    when 'Employee_Wise_Account_Target__c' {
                        Employee_Wise_Account_Target__c rec = (Employee_Wise_Account_Target__c) record;
                        tempMap.put('ParameterId', rec.Account__c);
                        tempMap.put('ParameterName', rec.Account__r.Name);

                        for (Employee_Wise_Account_Target_Line_Item__c childRec: rec.Employee_Wise_Account_Target_Line_Item__r) {
                            Map < String, Object > childMap = new Map < String, Object > ();
                            childMap.put('ParameterId', childRec.Id);
                            childMap.put('Monthly_Target_Quantity__c', childRec.Monthly_Target_Quantity__c != null ? childRec.Monthly_Target_Quantity__c.setScale(2) : null);
                            childMap.put('Monthly_Target_Amount__c', childRec.Monthly_Target_Amount__c != null ? childRec.Monthly_Target_Amount__c.setScale(2) : null);
                            childMap.put('Actual_Quantity__c', childRec.Actual_Quantity__c != null ? childRec.Actual_Quantity__c.setScale(2) : null);
                            childMap.put('Pending_Quantity__c', childRec.Pending_Quantity__c != null ? childRec.Pending_Quantity__c.setScale(2) : null);
                            childMap.put('Actual_Amount__c', childRec.Actual_Amount__c != null ? childRec.Actual_Amount__c.setScale(2) : null);
                            childMap.put('Pending_Amount__c', childRec.Pending_Amount__c != null ? childRec.Pending_Amount__c.setScale(2) : null);
                            childMap.put('targetAmountEdit', false);

                            if (tempMap.containsKey('childData')) {
                                List < Object > tempList = (List < object > ) tempMap.get('childData');
                                tempList.add(childMap);
                            } else {
                                tempMap.put('childData', new List < Object > {
                                    childMap
                                });
                            }
                        }
                    }
                    
                    when 'Account_Wise_Product_Target__c' {
                        Account_Wise_Product_Target__c rec = (Account_Wise_Product_Target__c) record;
                        tempMap.put('ParameterId', rec.Product__c);
                        tempMap.put('ParameterName', rec.Product__r.Name);
                        tempMap.put('ParameterId1', rec.Employee__c);
                        tempMap.put('ParameterName1', rec.Employee__r.Name);

                        for (Account_Wise_Product_Target_Line_Item__c childRec: rec.Account_Wise_Product_Target_Line_Item__r) {
                            Map < String, Object > childMap = new Map < String, Object > ();
                            childMap.put('ParameterId', childRec.Id);
                            childMap.put('Monthly_Target_Quantity__c', childRec.Monthly_Target_Quantity__c != null ? childRec.Monthly_Target_Quantity__c.setScale(2) : null);
                            childMap.put('Monthly_Target_Amount__c', childRec.Monthly_Target_Amount__c != null ? childRec.Monthly_Target_Amount__c.setScale(2) : null);
                            childMap.put('Actual_Quantity__c', childRec.Actual_Quantity__c != null ? childRec.Actual_Quantity__c.setScale(2) : null);
                            childMap.put('Pending_Quantity__c', childRec.Pending_Quantity__c != null ? childRec.Pending_Quantity__c.setScale(2) : null);
                            childMap.put('Actual_Amount__c', childRec.Actual_Amount__c != null ? childRec.Actual_Amount__c.setScale(2) : null);
                            childMap.put('Pending_Amount__c', childRec.Pending_Amount__c != null ? childRec.Pending_Amount__c.setScale(2) : null);
                            childMap.put('targetAmountEdit', false);

                            if (tempMap.containsKey('childData')) {
                                List < Object > tempList = (List < object > ) tempMap.get('childData');
                                tempList.add(childMap);
                            } else {
                                tempMap.put('childData', new List < Object > {
                                    childMap
                                });
                            }
                        }
                    }
                }

                if (result.containsKey('parameterData')) {
                    List < Object > tempList = (List < Object > ) result.get('parameterData');
                    tempList.add(tempMap);
                } else {
                    result.put('parameterData', new List < Object > {
                        tempMap
                    });
                }
            }

            return JSON.serialize(result);

        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
}