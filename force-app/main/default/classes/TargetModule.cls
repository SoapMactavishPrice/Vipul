public with sharing class TargetModule {
    
    public TargetModule() {
        
    }
    
    // Add this helper method to check if user is System Administrator
    private static Boolean isSystemAdministrator() {
        return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name == 'System Administrator';
    }
    
    @AuraEnabled(cacheable = true)
    public static string getDefaultFilterValues() {
        try {
            Map < String, Object > result = new Map < String, Object > ();
            result.put('Fiscal_Year__c', [SELECT Id FROM Fiscal_Year__c WHERE isActive__c = true LIMIT 1].Id);
            
            Map < Id, List < Map < String, String >>> userMapCompanyWise = new Map < Id, List < Map < String, String >>> ();
            for (User u: [SELECT Id, Name FROM User]) { // Data	Cls.getUserMaster()
                Map < String, String > tempMap = new Map < String, String > ();
                {
                    List < Map < String, String >> tempList = new List < Map < String, String >> ();
                    tempMap.put('label', u.Name);
                    tempMap.put('value', u.Id);
                    tempList.add(tempMap);
                    userMapCompanyWise.put(u.Id, tempList);
                }
            }
            System.debug('Before====>' + result);
            result.put('userMapCompanyWise', userMapCompanyWise);
            System.debug('A====>' + result);
            
            return JSON.serialize(result);
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
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
            
            Boolean isComplete = [select is_Complete__c from Fiscal_Year__c where Id = :fiscId].is_Complete__c;
            
            Map<String, Object> result = new Map<String, Object>();
            List<Map<String, Object>> parameterData = new List<Map<String, Object>>();
            Set<String> masterRecordIds = new Set<String>();
            Integer index = 0;
            
            String queryFront = '';
            String whr = '';
            String ordBy = ' ORDER BY Name ASC ';
            
            whr += ' WHERE Fiscal_Year__c = \'' + fiscId + '\' ';
            System.debug(whr);
            system.debug(parentTab + ' ' + masterRecordIds);
            
            switch on parentTab {
                when 'Employee_Wise_Target__c' {
                    queryFront = 'SELECT Id, Employee__c, Employee__r.Name, Employee__r.User_Division__c, ' +
                        'Fiscal_Year__c, Fiscal_Year__r.Name, Fiscal_Year__r.isActive__c, Fiscal_Year__r.is_Complete__c, Fiscal_Year__r.Is_Planning__c, ' +
                        'Target_Quantity__c, Target_Amount__c ' +
                        'FROM ' + parentTab + ' ';
                    
                    whr += ' AND Employee__c IN: masterRecordIds ';
                    
                    Boolean isSystemAdmin = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name == 'System Administrator';
                    
                    List<User> users;
                    if (isSystemAdmin) {
                        users = [SELECT Id, Name, User_Division__c FROM User 
                                 WHERE isActive = TRUE 
                                 AND Profile.UserLicense.Name = 'Salesforce' 
                                 ORDER BY Name ASC];
                    } else {
                        users = [SELECT Id, Name, User_Division__c FROM User 
                                 WHERE Id = :UserInfo.getUserId() 
                                 AND isActive = TRUE];
                    }
                    
                    if (users.size() == 0) {
                        return '{}';
                    }
                    
                    for (User u: users) {
                        Map<String, Object> tempMap = new Map<String, Object>();
                        tempMap.put('ParameterId', u.Id);
                        tempMap.put('ParameterName', u.Name);
                        tempMap.put('division', u.User_Division__c);
                        tempMap.put('ParameterEdit', false);
                        tempMap.put('Target_Amount__c', null);
                        tempMap.put('Target_Amount_INR__c', null);
                        tempMap.put('Target_Amount_USD__c', null);
                        tempMap.put('targetAmountEdit', !isComplete);
                        parameterData.add(tempMap);
                        masterRecordIds.add(u.Id);
                    }
                }
                
                when 'Employee_Wise_Account_Target__c' {
                    queryFront = 'SELECT Id, Name, Account__c, Account__r.Name, Employee__c, Employee__r.User_Division__c, ' +
                        'Fiscal_Year__c, Fiscal_Year__r.Name, Fiscal_Year__r.isActive__c, Fiscal_Year__r.is_Complete__c, Fiscal_Year__r.Is_Planning__c, ' +
                        'Target_Quantity__c, Target_Amount__c ' +
                        'FROM ' + parentTab + ' ';
                    
                    whr += ' AND Employee__c = :empId';
                    
                    String currentUserId = UserInfo.getUserId();
                    User currentUser = [SELECT Profile.Name FROM User WHERE Id = :currentUserId];
                    String profileName = currentUser.Profile.Name;
                    Boolean isSystemAdmin = (profileName == 'System Administrator');
                    
                    if (!isSystemAdmin && empId != currentUserId) {
                        System.debug('Non-admin user tried to access data for another user. Access denied.');
                        return JSON.serialize(parameterData);
                    }
                    
                    // First get existing targets to identify which accounts have data
                    Map<Id, Employee_Wise_Account_Target__c> existingTargets = new Map<Id, Employee_Wise_Account_Target__c>();
                    for (Employee_Wise_Account_Target__c ewat : [
                        SELECT Id, Account__c, Target_Quantity__c, Target_Amount__c 
                        FROM Employee_Wise_Account_Target__c 
                        WHERE Employee__c = :empId 
                        AND Fiscal_Year__c = :fiscId
                    ]) {
                        existingTargets.put(ewat.Account__c, ewat);
                    }
                    
                    // Get all accounts owned by the employee
                    String AccountQuery = 'SELECT Id, Name FROM Account WHERE OwnerId = :empId ORDER BY Name ASC';
                    List<Account> AccountList = Database.query(AccountQuery);
                    
                    if (AccountList.isEmpty()) {
                        return JSON.serialize(parameterData);
                    }
                    
                    // Get employee division for all accounts
                    User empUser = [SELECT Id, User_Division__c FROM User WHERE Id = :empId];
                    String division = empUser.User_Division__c;
                    
                    // Create two lists: accounts with targets and accounts without targets
                    List<Account> accountsWithTargets = new List<Account>();
                    List<Account> accountsWithoutTargets = new List<Account>();
                    
                    for (Account a : AccountList) {
                        if (existingTargets.containsKey(a.Id) && 
                            (existingTargets.get(a.Id).Target_Quantity__c != null || 
                             existingTargets.get(a.Id).Target_Amount__c != null)) {
                                 accountsWithTargets.add(a);
                             } else {
                                 accountsWithoutTargets.add(a);
                             }
                    }
                    
                    // Combine lists: accounts with targets first, then accounts without targets
                    List<Account> sortedAccounts = new List<Account>();
                    sortedAccounts.addAll(accountsWithTargets);
                    sortedAccounts.addAll(accountsWithoutTargets);
                    
                    for (Account a : sortedAccounts) {
                        Map<String, Object> tempMap = new Map<String, Object>();
                        tempMap.put('ParameterId', a.Id);
                        tempMap.put('ParameterName', a.Name);
                        tempMap.put('division', division);
                        tempMap.put('ParameterEdit', false);
                        
                        // Set values from existing target if available
                        if (existingTargets.containsKey(a.Id)) {
                            Employee_Wise_Account_Target__c existingTarget = existingTargets.get(a.Id);
                            tempMap.put('Target_Quantity__c', existingTarget.Target_Quantity__c != null ? existingTarget.Target_Quantity__c.setScale(2) : null);
                            tempMap.put('Target_Quantity_New__c', existingTarget.Target_Quantity__c != null ? existingTarget.Target_Quantity__c.setScale(2) : null);
                            
                            if(existingTarget.Target_Amount__c == null){
                                tempMap.put('Target_Amount__c', '');
                                tempMap.put('Target_Amount_INR__c', '');
                                tempMap.put('Target_Amount_USD__c', '');
                            } else {
                                Decimal amt = existingTarget.Target_Amount__c.setScale(2);
                                tempMap.put('Target_Amount__c', amt);
                                if (division == 'International') {
                                    tempMap.put('Target_Amount_USD__c', amt);
                                } else {
                                    tempMap.put('Target_Amount_INR__c', amt);
                                }
                            }
                        } else {
                            tempMap.put('Target_Quantity__c', null);
                            tempMap.put('Target_Quantity_New__c', null);
                            tempMap.put('Target_Amount__c', null);
                            tempMap.put('Target_Amount_INR__c', null);
                            tempMap.put('Target_Amount_USD__c', null);
                        }
                        
                        tempMap.put('targetAmountEdit', !isComplete);
                        
                        masterRecordIds.add(a.Id);
                        parameterData.add(tempMap);
                    }
                }
                
             when 'Account_Wise_Product_Target__c' {
    queryFront = 'SELECT Id, Name, Product__c, Product_Code__c, Description__c, Product__r.Name, ' +
        'Employee__c, Employee__r.User_Division__c, Account__c, Account__r.Name, ' +
        'Fiscal_Year__c, Fiscal_Year__r.Name, Fiscal_Year__r.isActive__c, Fiscal_Year__r.is_Complete__c, Fiscal_Year__r.Is_Planning__c, ' +
        'Target_Quantity__c, Target_Amount__c ' +
        'FROM ' + parentTab + ' ';
    
    String currentUserId = UserInfo.getUserId();
    User currentUser = [SELECT Profile.Name FROM User WHERE Id = :currentUserId];
    String profileName = currentUser.Profile.Name;
    Boolean isSystemAdmin = (profileName == 'System Administrator');
    
    if (!isSystemAdmin && empId != currentUserId) {
        System.debug('Access denied: Non-admin selected another employee.');
        return JSON.serialize(parameterData);
    }
    
    if (!isSystemAdmin) {
        List<Account> validAccounts = [
            SELECT Id FROM Account WHERE OwnerId = :currentUserId AND Id = :accId
        ];
        if (validAccounts.isEmpty()) {
            System.debug('Access denied: Selected account not created by current user.');
            return JSON.serialize(parameterData);
        }
    }
    
    whr += ' AND Account__c = :accId ';
    whr += ' AND Employee__c = :empId ';
    
    // First get existing targets to identify which products have data
    Map<Id, Account_Wise_Product_Target__c> existingTargets = new Map<Id, Account_Wise_Product_Target__c>();
    for (Account_Wise_Product_Target__c awpt : [
        SELECT Id, Product__c, Target_Quantity__c, Target_Amount__c 
        FROM Account_Wise_Product_Target__c 
        WHERE Account__c = :accId 
        AND Employee__c = :empId
        AND Fiscal_Year__c = :fiscId
    ]) {
        existingTargets.put(awpt.Product__c, awpt);
    }
    
    // Get employee division for all products
    User empUser = [SELECT Id, User_Division__c FROM User WHERE Id = :empId];
    String division = empUser.User_Division__c;
    
    String ProductQuery = 'SELECT Id, Name, ProductCode, Description FROM Product2 ORDER BY Name ASC';
    List<Product2> Product = Database.query(ProductQuery);
    
    if (Product.isEmpty()) {
        return JSON.serialize(parameterData);
    }
    
    // Create two lists: products with targets and products without targets
    List<Product2> productsWithTargets = new List<Product2>();
    List<Product2> productsWithoutTargets = new List<Product2>();
    
    for (Product2 p : Product) {
        if (existingTargets.containsKey(p.Id) && 
            (existingTargets.get(p.Id).Target_Quantity__c != null || 
             existingTargets.get(p.Id).Target_Amount__c != null)) {
            productsWithTargets.add(p);
        } else {
            productsWithoutTargets.add(p);
        }
    }
    
    // Combine lists: products with targets first, then products without targets
    List<Product2> sortedProducts = new List<Product2>();
    sortedProducts.addAll(productsWithTargets);
    sortedProducts.addAll(productsWithoutTargets);
    
    for (Product2 p : sortedProducts) {
        Map<String, Object> tempMap = new Map<String, Object>();
        tempMap.put('ParameterId', p.Id);
        tempMap.put('ParameterName', p.Name);
        tempMap.put('ParameterCode', p.ProductCode);
        tempMap.put('ParameterDesc', p.Description);
        tempMap.put('division', division);
        tempMap.put('ParameterEdit', false);
        
        // Set values from existing target if available
        if (existingTargets.containsKey(p.Id)) {
            Account_Wise_Product_Target__c existingTarget = existingTargets.get(p.Id);
            tempMap.put('Target_Quantity__c', existingTarget.Target_Quantity__c != null ? existingTarget.Target_Quantity__c.setScale(2) : null);
            tempMap.put('Target_Quantity_New__c', existingTarget.Target_Quantity__c != null ? existingTarget.Target_Quantity__c.setScale(2) : null);
            
            if(existingTarget.Target_Amount__c == null){
                tempMap.put('Target_Amount__c', '');
                tempMap.put('Target_Amount_INR__c', '');
                tempMap.put('Target_Amount_USD__c', '');
            } else {
                Decimal amt = existingTarget.Target_Amount__c.setScale(2);
                tempMap.put('Target_Amount__c', amt);
                if (division == 'International') {
                    tempMap.put('Target_Amount_USD__c', amt);
                } else {
                    tempMap.put('Target_Amount_INR__c', amt);
                }
            }
        } else {
            tempMap.put('Target_Quantity__c', null);
            tempMap.put('Target_Quantity_New__c', null);
            tempMap.put('Target_Amount__c', null);
            tempMap.put('Target_Amount_INR__c', null);
            tempMap.put('Target_Amount_USD__c', null);
        }
        
        tempMap.put('targetAmountEdit', !isComplete);
        
        masterRecordIds.add(p.Id);
        parameterData.add(tempMap);
    }
}
                
                when 'Employee_Wise_Product_Target__c' {
                    queryFront = 'SELECT Id, Name, Product__c, Product_Code__c, Description__c, Product__r.Name, Employee__c, Employee__r.User_Division__c, ' +
                        'Fiscal_Year__c, Fiscal_Year__r.Name, Fiscal_Year__r.isActive__c, Fiscal_Year__r.is_Complete__c, Fiscal_Year__r.Is_Planning__c, ' +
                        'Target_Quantity__c, Target_Amount__c ' +
                        'FROM ' + parentTab + ' ';
                    
                    whr += ' AND Employee__c =: empId ';
                    
                    String ProductQuery = 'SELECT Id, Name, ProductCode, Description from Product2 order by Name ASC';
                    List<Product2> Product = Database.query(ProductQuery);
                    
                    if (Product.size() == 0) {
                        return JSON.serialize(parameterData);
                    }
                    
                    // Get employee division for all products
                    User empUser = [SELECT Id, User_Division__c FROM User WHERE Id = :empId];
                    String division = empUser.User_Division__c;
                    
                    for (Product2 p: Product) {
                        Map<String, Object> tempMap = new Map<String, Object>();
                        tempMap.put('ParameterId', p.Id);
                        tempMap.put('ParameterName', p.Name);
                        tempMap.put('ParameterCode', p.ProductCode);
                        tempMap.put('ParameterDesc', p.Description);
                        tempMap.put('division', division);
                        tempMap.put('ParameterEdit', false);
                        tempMap.put('Target_Quantity_New__c', null);
                        tempMap.put('Target_Amount__c', null);
                        tempMap.put('Target_Amount_INR__c', null);
                        tempMap.put('Target_Amount_USD__c', null);
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
                Map<String, Object> tempMap = new Map<String, Object>();
                tempMap.put('Id', record.Id);
                
                // Get division from employee
                String division = (String)record.getSObject('Employee__r')?.get('User_Division__c');
                tempMap.put('division', division);
                
                // Handle amount based on division
                Decimal amount = (Decimal)record.get('Target_Amount__c');
                tempMap.put('Target_Amount__c', amount);
                
                if (division == 'International') {
                    tempMap.put('Target_Amount_USD__c', amount);
                    tempMap.put('Target_Amount_INR__c', null);
                } else {
                    tempMap.put('Target_Amount_INR__c', amount);
                    tempMap.put('Target_Amount_USD__c', null);
                }
                
                switch on parentTab {
                    when 'Employee_Wise_Target__c' {
                        Employee_Wise_Target__c rec = (Employee_Wise_Target__c) record;
                        tempMap.put('ParameterId', rec.Employee__c);
                        tempMap.put('ParameterName', rec.Employee__r.Name);
                        tempMap.put('ParameterEdit', false);
                        
                        if(rec.Target_Amount__c == null){
                            tempMap.put('Target_Amount__c', '');
                            tempMap.put('Target_Amount_INR__c', '');
                            tempMap.put('Target_Amount_USD__c', '');
                        } else {
                            Decimal amt = rec.Target_Amount__c.setScale(2);
                            tempMap.put('Target_Amount__c', amt);
                            if (division == 'International') {
                                tempMap.put('Target_Amount_USD__c', amt);
                            } else {
                                tempMap.put('Target_Amount_INR__c', amt);
                            }
                        }
                        
                        if (rec.Fiscal_Year__r.Is_Planning__c || rec.Fiscal_Year__r.isActive__c) {
                            tempMap.put('targetAmountEdit', true);
                        } else if (rec.Fiscal_Year__r.is_Complete__c) {
                            tempMap.put('targetAmountEdit', false);
                        }
                        
                        for (Integer j = 0; j < parameterData.size(); j++) {
                            Map<String, Object> empData = (Map<String, Object>) parameterData[j];
                            if (tempMap.get('ParameterName') == empData.get('ParameterName')) {
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
                        tempMap.put('Target_Quantity_New__c', rec.Target_Quantity__c != null ? rec.Target_Quantity__c.setScale(2) : null);
                        
                        if(rec.Target_Amount__c == null){
                            tempMap.put('Target_Amount__c', '');
                            tempMap.put('Target_Amount_INR__c', '');
                            tempMap.put('Target_Amount_USD__c', '');
                        } else {
                            Decimal amt = rec.Target_Amount__c.setScale(2);
                            tempMap.put('Target_Amount__c', amt);
                            if (division == 'International') {
                                tempMap.put('Target_Amount_USD__c', amt);
                            } else {
                                tempMap.put('Target_Amount_INR__c', amt);
                            }
                        }
                        
                        if (rec.Fiscal_Year__r.Is_Planning__c || rec.Fiscal_Year__r.isActive__c) {
                            tempMap.put('targetAmountEdit', true);
                        } else if (rec.Fiscal_Year__r.is_Complete__c) {
                            tempMap.put('targetAmountEdit', false);
                        }
                        
                        for (Integer j = 0; j < parameterData.size(); j++) {
                            Map<String, Object> accData = (Map<String, Object>) parameterData[j];
                            if (tempMap.get('ParameterName') == accData.get('ParameterName')) {
                                parameterData[j] = tempMap;
                                break;
                            }
                        }
                    }
                    
                    when 'Account_Wise_Product_Target__c' {
                        Account_Wise_Product_Target__c rec = (Account_Wise_Product_Target__c) record;
                        tempMap.put('ParameterId', rec.Product__c);
                        tempMap.put('ParameterName', rec.Product__r.Name);
                        tempMap.put('ParameterCode', rec.Product_Code__c);
                        tempMap.put('ParameterDesc', rec.Description__c);
                        tempMap.put('ParameterEdit', false);
                        tempMap.put('Target_Quantity__c', rec.Target_Quantity__c != null ? rec.Target_Quantity__c.setScale(2) : null);
                        tempMap.put('Target_Quantity_New__c', rec.Target_Quantity__c != null ? rec.Target_Quantity__c.setScale(2) : null);
                        
                        if(rec.Target_Amount__c == null){
                            tempMap.put('Target_Amount__c', '');
                            tempMap.put('Target_Amount_INR__c', '');
                            tempMap.put('Target_Amount_USD__c', '');
                        } else {
                            Decimal amt = rec.Target_Amount__c.setScale(2);
                            tempMap.put('Target_Amount__c', amt);
                            if (division == 'International') {
                                tempMap.put('Target_Amount_USD__c', amt);
                            } else {
                                tempMap.put('Target_Amount_INR__c', amt);
                            }
                        }
                        
                        if (rec.Fiscal_Year__r.Is_Planning__c || rec.Fiscal_Year__r.isActive__c) {
                            tempMap.put('targetAmountEdit', true);
                        } else if (rec.Fiscal_Year__r.is_Complete__c) {
                            tempMap.put('targetAmountEdit', false);
                        }
                        
                        for (Integer j = 0; j < parameterData.size(); j++) {
                            Map<String, Object> prodData = (Map<String, Object>) parameterData[j];
                            if (tempMap.get('ParameterName') == prodData.get('ParameterName')) {
                                parameterData[j] = tempMap;
                                break;
                            }
                        }
                    }
                    
                    when 'Employee_Wise_Product_Target__c' {
                        Employee_Wise_Product_Target__c rec = (Employee_Wise_Product_Target__c) record;
                        tempMap.put('ParameterId', rec.Product__c);
                        tempMap.put('ParameterName', rec.Product__r.Name);
                        tempMap.put('ParameterCode', rec.Product_Code__c);
                        tempMap.put('ParameterDesc', rec.Description__c);
                        tempMap.put('ParameterEdit', false);
                        tempMap.put('Target_Quantity__c', rec.Target_Quantity__c != null ? rec.Target_Quantity__c.setScale(2) : null);
                        tempMap.put('Target_Quantity_New__c', rec.Target_Quantity__c != null ? rec.Target_Quantity__c.setScale(2) : null);
                        
                        if(rec.Target_Amount__c == null){
                            tempMap.put('Target_Amount__c', '');
                            tempMap.put('Target_Amount_INR__c', '');
                            tempMap.put('Target_Amount_USD__c', '');
                        } else {
                            Decimal amt = rec.Target_Amount__c.setScale(2);
                            tempMap.put('Target_Amount__c', amt);
                            if (division == 'International') {
                                tempMap.put('Target_Amount_USD__c', amt);
                            } else {
                                tempMap.put('Target_Amount_INR__c', amt);
                            }
                        }
                        
                        if (rec.Fiscal_Year__r.Is_Planning__c || rec.Fiscal_Year__r.isActive__c) {
                            tempMap.put('targetAmountEdit', true);
                        } else if (rec.Fiscal_Year__r.is_Complete__c) {
                            tempMap.put('targetAmountEdit', false);
                        }
                        
                        for (Integer j = 0; j < parameterData.size(); j++) {
                            Map<String, Object> prodData = (Map<String, Object>) parameterData[j];
                            if (tempMap.get('ParameterName') == prodData.get('ParameterName')) {
                                parameterData[j] = tempMap;
                                break;
                            }
                        }
                    }
                }
                index++;
            }
            
            result.put('parameterData', parameterData);
            return JSON.serialize(result);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
    @AuraEnabled
    public static string getMonthly(String fiscId, String empId, String parentTab, String prodCatVal, String accId) {
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
            
            Map<String, Object> result = new Map<String, Object>();
            
            // Get months for the fiscal year
            List<String> months = new List<String>();
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
                        '(SELECT Id, Start_Date__c, End_Date__c, Monthly_Target_Quantity__c, Monthly_Target_Amount__c FROM Employee_Wise_Target_Line_Items__r ORDER BY Start_Date__c) ' +
                        ' FROM ' + parentTab + ' ';
                    ordBy = ' ORDER BY Employee__r.Name ASC ';
                    
                    if (!isSystemAdmin) {
                        // For non-admin users, only show their own records
                        whr += ' AND Employee__c = \'' + UserInfo.getUserId() + '\' ';
                    }
                }
                
                when 'Employee_Wise_Product_Target__c' {
                    queryFront = 'SELECT Id, Product__c,Product_Code__c,Description__c, Product__r.Name, Product__r.ProductCode,Product__r.Description, Product__r.Family, ' +
                        '(SELECT Id, Start_Date__c, End_Date__c, Monthly_Target_Quantity__c,Monthly_Target_Amount__c FROM Employee_Wise_Product_Target_Line_Items__r ORDER BY Start_Date__c) ' +
                        ' FROM ' + parentTab + ' ';
                    whr += ' AND Employee__c = \'' + empId + '\' ';
                    ordBy = ' ORDER BY Product__r.Name ASC ';
                }
                
                when 'Employee_Wise_Account_Target__c' {
                    queryFront = 'SELECT Id, Account__c, Account__r.Name, Start_Date__c, ' +
                        '(SELECT Id, Start_Date__c, End_Date__c, Monthly_Target_Quantity__c,Monthly_Target_Amount__c FROM Employee_Wise_Account_Target_Line_Item__r ORDER BY Start_Date__c) ' +
                        ' FROM ' + parentTab + ' ';
                    
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
                    queryFront = 'SELECT Id, Product__c, Product_Code__c, Description__c, Product__r.Name, Product__r.ProductCode, Product__r.Description, Product__r.Family, Account__c, Account__r.Name, ' +
                        '(SELECT Id, Start_Date__c, End_Date__c, Monthly_Target_Quantity__c, Monthly_Target_Amount__c ' +
                        ' FROM Account_Wise_Product_Target_Line_Item__r ORDER BY Start_Date__c) ' +
                        ' FROM ' + parentTab + ' ';
                    
                    whr += ' AND Account__c = \'' + accId + '\' ';
                    ordBy = ' ORDER BY Product__r.Name ASC ';
                }
            }
            
            String query = queryFront + whr + ordBy;
            System.debug(query);
            
            for (sObject record: Database.query(query)) {
                Map<String, Object> tempMap = new Map<String, Object>();
                tempMap.put('Id', record.Id);
                
                switch on parentTab {
                    when 'Employee_Wise_Target__c' {
                        Employee_Wise_Target__c rec = (Employee_Wise_Target__c) record;
                        tempMap.put('ParameterId', rec.Employee__c);
                        tempMap.put('ParameterName', rec.Employee__r.Name);
                        
                        for (Employee_Wise_Target_Line_Item__c childRec: rec.Employee_Wise_Target_Line_Items__r) {
                            Map<String, Object> childMap = new Map<String, Object>();
                            childMap.put('ParameterId', childRec.Id);
                            childMap.put('Monthly_Target_Amount__c', childRec.Monthly_Target_Amount__c.setScale(2));
                            if (childRec.Start_Date__c > System.today()) {
                                childMap.put('targetAmountEdit', true);
                            } else if (childRec.Start_Date__c <= System.today() && System.today() <= childRec.End_Date__c) {
                                childMap.put('targetAmountEdit', true);
                            } else {
                                childMap.put('targetAmountEdit', false);
                            }
                            
                            if (tempMap.containsKey('childData')) {
                                List<Object> tempList = (List<object>) tempMap.get('childData');
                                tempList.add(childMap);
                            } else {
                                tempMap.put('childData', new List<Object>{childMap});
                            }
                        }
                    }
                    
                    when 'Employee_Wise_Product_Target__c' {
                        Employee_Wise_Product_Target__c rec = (Employee_Wise_Product_Target__c) record;
                        tempMap.put('ParameterId', rec.Product__c);
                        tempMap.put('ParameterName', rec.Product__r.Name);
                        tempMap.put('ParameterCode', rec.Product__r.ProductCode);
                        tempMap.put('ParameterDesc', rec.Product__r.Description);
                        
                        
                        for (Employee_Wise_Product_Target_Line_Item__c childRec: rec.Employee_Wise_Product_Target_Line_Items__r) {
                            Map<String, Object> childMap = new Map<String, Object>();
                            childMap.put('ParameterId', childRec.Id);
                            childMap.put('Monthly_Target_Quantity__c', childRec.Monthly_Target_Quantity__c.setScale(2));
                            childMap.put('Monthly_Target_Amount__c', childRec.Monthly_Target_Amount__c.setScale(2));
                            if (childRec.Start_Date__c > System.today()) {
                                childMap.put('targetAmountEdit', true);
                            } else if (childRec.Start_Date__c <= System.today() && System.today() <= childRec.End_Date__c) {
                                childMap.put('targetAmountEdit', true);
                            } else {
                                childMap.put('targetAmountEdit', false);
                            }
                            
                            if (tempMap.containsKey('childData')) {
                                List<Object> tempList = (List<object>) tempMap.get('childData');
                                tempList.add(childMap);
                            } else {
                                tempMap.put('childData', new List<Object>{childMap});
                            }
                        }
                    }
                    
                    when 'Employee_Wise_Account_Target__c' {
                        Employee_Wise_Account_Target__c rec = (Employee_Wise_Account_Target__c) record;
                        tempMap.put('ParameterId', rec.Account__c);
                        tempMap.put('ParameterName', rec.Account__r.Name);
                        
                        for (Employee_Wise_Account_Target_Line_Item__c childRec: rec.Employee_Wise_Account_Target_Line_Item__r) {
                            Map<String, Object> childMap = new Map<String, Object>();
                            childMap.put('ParameterId', childRec.Id);
                            Decimal monthlyQty = childRec.Monthly_Target_Quantity__c != null ? childRec.Monthly_Target_Quantity__c.setScale(2) : 0.00;
                            childMap.put('Monthly_Target_Quantity__c', monthlyQty);
                            childMap.put('Monthly_Target_Amount__c', childRec.Monthly_Target_Amount__c.setScale(2));
                            if (childRec.Start_Date__c > System.today()) {
                                childMap.put('targetAmountEdit', true);
                            } else if (childRec.Start_Date__c <= System.today() && System.today() <= childRec.End_Date__c) {
                                childMap.put('targetAmountEdit', true);
                            } else {
                                childMap.put('targetAmountEdit', false);
                            }
                            
                            if (tempMap.containsKey('childData')) {
                                List<Object> tempList = (List<object>) tempMap.get('childData');
                                tempList.add(childMap);
                            } else {
                                tempMap.put('childData', new List<Object>{childMap});
                            }
                        }
                    }
                    
                    when 'Account_Wise_Product_Target__c' {
                        Account_Wise_Product_Target__c rec = (Account_Wise_Product_Target__c) record;
                        tempMap.put('ParameterId', rec.Product__c);
                        tempMap.put('ParameterName', rec.Product__r.Name);
                        tempMap.put('ParameterCode', rec.Product__r.ProductCode);
                        tempMap.put('ParameterDesc', rec.Product__r.Description);
                        
                        for (Account_Wise_Product_Target_Line_Item__c childRec: rec.Account_Wise_Product_Target_Line_Item__r) {
                            Map<String, Object> childMap = new Map<String, Object>();
                            childMap.put('ParameterId', childRec.Id);
                            Decimal monthlyQty = childRec.Monthly_Target_Quantity__c != null ? childRec.Monthly_Target_Quantity__c.setScale(2) : 0.00;
                            childMap.put('Monthly_Target_Quantity__c', monthlyQty);
                            childMap.put('Monthly_Target_Amount__c', childRec.Monthly_Target_Amount__c.setScale(2));
                            if (childRec.Start_Date__c > System.today()) {
                                childMap.put('targetAmountEdit', true);
                            } else if (childRec.Start_Date__c <= System.today() && System.today() <= childRec.End_Date__c) {
                                childMap.put('targetAmountEdit', true);
                            } else {
                                childMap.put('targetAmountEdit', false);
                            }
                            
                            if (tempMap.containsKey('childData')) {
                                List<Object> tempList = (List<Object>) tempMap.get('childData');
                                tempList.add(childMap);
                            } else {
                                tempMap.put('childData', new List<Object>{childMap});
                            }
                        }
                    }
                }
                
                if (result.containsKey('parameterData')) {
                    List<Object> tempList = (List<Object>) result.get('parameterData');
                    tempList.add(tempMap);
                } else {
                    result.put('parameterData', new List<Object>{tempMap});
                }
            }
            
            return JSON.serialize(result);
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
    
    
    @AuraEnabled(cacheable=false)
    public static string saveRecords(String data, String fiscalYearId, String employeeId, String type, String subType, String accId) {
        try {
            System.debug('saveRecords called with data: ' + data);
            Map<String, Object> result = new Map<String, Object>();
            List<sObject> records = new List<sObject>();
            List<Object> dataMap = (List<Object>)JSON.deserializeUntyped(data);
            CurrencyType usdCurrency = [SELECT Id, IsoCode, ConversionRate FROM CurrencyType WHERE IsoCode = 'USD' LIMIT 1];
            
            if (subType == 'Yearly') {
                for (Object obj : dataMap) {
                    Map<String, Object> recMap = (Map<String, Object>)obj;
                    System.debug('Processing record: ' + recMap);
                    
                    switch on type {
                        when 'Employee_Wise_Target__c' {
                            Employee_Wise_Target__c rec = new Employee_Wise_Target__c();
                            
                            // Handle existing or new record
                            if (String.isNotBlank(String.valueOf(recMap.get('Id')))) {
                                rec.Id = String.valueOf(recMap.get('Id'));
                            } else {
                                rec.Fiscal_Year__c = fiscalYearId;
                            }
                            
                            // Set common fields
                            rec.Employee__c = String.valueOf(recMap.get('ParameterId'));
                            
                            // Handle amount based on division
                            String division = (String)recMap.get('division');
                            
                            System.debug(parseDecimalSafe(recMap.get('Target_Amount_USD__c')));
                            System.debug(usdCurrency.ConversionRate);
                            
                            if (division == 'International') {
                                rec.CurrencyIsoCode = 'USD';
                                // rec.Target_Amount__c = parseDecimalSafe(recMap.get('Target_Amount_USD__c')) / usdCurrency.ConversionRate;
                                rec.Target_Amount__c = parseDecimalSafe(recMap.get('Target_Amount_USD__c'));
                            } else {
                                rec.Target_Amount__c = parseDecimalSafe(recMap.get('Target_Amount_INR__c'));
                            }
                            
                            // Preserve quantity fields
                            if (recMap.containsKey('Target_Quantity__c')) {
                                rec.Target_Quantity__c = parseDecimalSafe(recMap.get('Target_Quantity__c'));
                            }
                            
                            System.debug('Saving Employee_Wise_Target__c: ' + rec);
                            records.add(rec);
                        }
                        when 'Employee_Wise_Account_Target__c' {
                            Employee_Wise_Account_Target__c rec = new Employee_Wise_Account_Target__c();
                            
                            if (String.isNotBlank(String.valueOf(recMap.get('Id')))) {
                                rec.Id = String.valueOf(recMap.get('Id'));
                            } else {
                                rec.Fiscal_Year__c = fiscalYearId;
                                rec.Employee__c = employeeId;
                            }
                            
                            rec.Account__c = String.valueOf(recMap.get('ParameterId'));
                            
                            // Handle amount based on division
                            String division = (String)recMap.get('division');
                            
                            if (division == 'International') {
                                rec.CurrencyIsoCode = 'USD';
                                // rec.Target_Amount__c = parseDecimalSafe(recMap.get('Target_Amount_USD__c')) / usdCurrency.ConversionRate;
                                rec.Target_Amount__c = parseDecimalSafe(recMap.get('Target_Amount_USD__c'));
                            } else {
                                rec.Target_Amount__c = parseDecimalSafe(recMap.get('Target_Amount_INR__c'));
                            }
                            
                            // Preserve quantity fields
                            if (recMap.containsKey('Target_Quantity__c')) {
                                rec.Target_Quantity__c = parseDecimalSafe(recMap.get('Target_Quantity__c'));
                            }
                            
                            System.debug('Saving Employee_Wise_Account_Target__c: ' + rec);
                            records.add(rec);
                        }
                        when 'Account_Wise_Product_Target__c' {
                            Account_Wise_Product_Target__c rec = new Account_Wise_Product_Target__c();
                            
                            if (String.isNotBlank(String.valueOf(recMap.get('Id')))) {
                                rec.Id = String.valueOf(recMap.get('Id'));
                            } else {
                                rec.Fiscal_Year__c = fiscalYearId;
                                rec.Account__c = accId;
                                rec.Employee__c = employeeId;
                            }
                            
                            rec.Product__c = String.valueOf(recMap.get('ParameterId'));
                            rec.Product_Code__c = String.valueOf(recMap.get('ParameterCode'));
                            rec.Description__c = String.valueOf(recMap.get('ParameterDesc'));
                            
                            // Handle amount based on division
                            String division = (String)recMap.get('division');
                            if (division == 'International') {
                                rec.CurrencyIsoCode = 'USD';
                                //      rec.Target_Amount__c = parseDecimalSafe(recMap.get('Target_Amount_USD__c')) / usdCurrency.ConversionRate;
                                rec.Target_Amount__c = parseDecimalSafe(recMap.get('Target_Amount_USD__c'));
                            } else {
                                rec.Target_Amount__c = parseDecimalSafe(recMap.get('Target_Amount_INR__c'));
                            }
                            
                            // Preserve quantity fields
                            if (recMap.containsKey('Target_Quantity__c')) {
                                rec.Target_Quantity__c = parseDecimalSafe(recMap.get('Target_Quantity__c'));
                            }
                            
                            System.debug('Saving Account_Wise_Product_Target__c: ' + rec);
                            records.add(rec);
                        }
                        when 'Employee_Wise_Product_Target__c' {
                            Employee_Wise_Product_Target__c rec = new Employee_Wise_Product_Target__c();
                            
                            if (String.isNotBlank(String.valueOf(recMap.get('Id')))) {
                                rec.Id = String.valueOf(recMap.get('Id'));
                            } else {
                                rec.Fiscal_Year__c = fiscalYearId;
                                rec.Employee__c = employeeId;
                            }
                            
                            rec.Product__c = String.valueOf(recMap.get('ParameterId'));
                            rec.Product_Code__c = String.valueOf(recMap.get('ParameterCode'));
                            rec.Description__c = String.valueOf(recMap.get('ParameterDesc'));
                            
                            // Handle amount based on division
                            String division = (String)recMap.get('division');
                            if (division == 'International') {
                                rec.CurrencyIsoCode = 'USD';
                                rec.Target_Amount__c = parseDecimalSafe(recMap.get('Target_Amount_USD__c')) / usdCurrency.ConversionRate;
                            } else {
                                rec.Target_Amount__c = parseDecimalSafe(recMap.get('Target_Amount_INR__c'));
                            }
                            
                            // Preserve quantity fields
                            if (recMap.containsKey('Target_Quantity__c')) {
                                rec.Target_Quantity__c = parseDecimalSafe(recMap.get('Target_Quantity__c'));
                            }
                            
                            System.debug('Saving Employee_Wise_Product_Target__c: ' + rec);
                            records.add(rec);
                        }
                    }
                }
            } else if (subType == 'Monthly') {
                for (Object obj : dataMap) {
                    Map<String, Object> recMap = (Map<String, Object>)obj;
                    
                    switch on type {
                        when 'Employee_Wise_Target__c' {
                            Employee_Wise_Target_Line_Item__c rec = new Employee_Wise_Target_Line_Item__c();
                            
                            if (String.isNotBlank(String.valueOf(recMap.get('Id')))) {
                                rec.Id = String.valueOf(recMap.get('Id'));
                            }
                            
                            rec.CurrencyIsoCode = 'USD';
                            rec.Monthly_Target_Amount__c = parseDecimalSafe(recMap.get('Monthly_Target_Amount__c')) / usdCurrency.ConversionRate;
                            rec.Monthly_Target_Quantity__c = parseDecimalSafe(recMap.get('Monthly_Target_Quantity__c'));
                            
                            System.debug('Saving Employee_Wise_Target_Line_Item__c: ' + rec);
                            records.add(rec);
                        }
                        when 'Employee_Wise_Account_Target__c' {
                            Employee_Wise_Account_Target_Line_Item__c rec = new Employee_Wise_Account_Target_Line_Item__c();
                            
                            if (String.isNotBlank(String.valueOf(recMap.get('Id')))) {
                                rec.Id = String.valueOf(recMap.get('Id'));
                            }
                            
                            rec.CurrencyIsoCode = 'USD';
                            rec.Monthly_Target_Amount__c = parseDecimalSafe(recMap.get('Monthly_Target_Amount__c')) / usdCurrency.ConversionRate;
                            rec.Monthly_Target_Quantity__c = parseDecimalSafe(recMap.get('Monthly_Target_Quantity__c'));
                            
                            System.debug('Saving Employee_Wise_Account_Target_Line_Item__c: ' + rec);
                            records.add(rec);
                        }
                        when 'Account_Wise_Product_Target__c' {
                            Account_Wise_Product_Target_Line_Item__c rec = new Account_Wise_Product_Target_Line_Item__c();
                            
                            if (String.isNotBlank(String.valueOf(recMap.get('Id')))) {
                                rec.Id = String.valueOf(recMap.get('Id'));
                            }
                            
                            rec.Product_Code__c = String.valueOf(recMap.get('ParameterCode'));
                            rec.Description__c = String.valueOf(recMap.get('ParameterDesc'));
                            rec.CurrencyIsoCode = 'USD';
                            rec.Monthly_Target_Amount__c = parseDecimalSafe(recMap.get('Monthly_Target_Amount__c')) / usdCurrency.ConversionRate;
                            rec.Monthly_Target_Quantity__c = parseDecimalSafe(recMap.get('Monthly_Target_Quantity__c'));
                            
                            System.debug('Saving Account_Wise_Product_Target_Line_Item__c: ' + rec);
                            records.add(rec);
                        }
                        when 'Employee_Wise_Product_Target__c' {
                            Employee_Wise_Product_Target_Line_Item__c rec = new Employee_Wise_Product_Target_Line_Item__c();
                            
                            if (String.isNotBlank(String.valueOf(recMap.get('Id')))) {
                                rec.Id = String.valueOf(recMap.get('Id'));
                            }
                            
                            rec.Product_Code__c = String.valueOf(recMap.get('ParameterCode'));
                            rec.Description__c = String.valueOf(recMap.get('ParameterDesc'));
                            rec.CurrencyIsoCode = 'USD';
                            rec.Monthly_Target_Amount__c = parseDecimalSafe(recMap.get('Monthly_Target_Amount__c')) / usdCurrency.ConversionRate;
                            rec.Monthly_Target_Quantity__c = parseDecimalSafe(recMap.get('Monthly_Target_Quantity__c'));
                            
                            System.debug('Saving Employee_Wise_Product_Target_Line_Item__c: ' + rec);
                            records.add(rec);
                        }
                    }
                }
            }
            
            result.put('status', 'Success');
            List<Object> errorList = new List<Object>();
            
            // Perform upsert and collect results
            List<Database.UpsertResult> upsertResults = Database.upsert(records, false);
            for (Integer i = 0; i < upsertResults.size(); i++) {
                Database.UpsertResult res = upsertResults[i];
                Map<String, Object> tempMap = new Map<String, Object>();
                tempMap.put('status', res.isSuccess());
                
                // Set appropriate ID based on record type
                switch on type {
                    when 'Employee_Wise_Target__c' {
                        tempMap.put('ParameterId', records[i].get('Employee__c'));
                    }
                    when 'Employee_Wise_Account_Target__c' {
                        tempMap.put('ParameterId', records[i].get('Account__c'));
                    }
                    when 'Account_Wise_Product_Target__c', 'Employee_Wise_Product_Target__c' {
                        tempMap.put('ParameterId', records[i].get('Product__c'));
                    }
                    when 'Employee_Wise_Target_Line_Item__c' {
                        tempMap.put('ParameterId', records[i].get('Id'));
                    }
                    when 'Employee_Wise_Account_Target_Line_Item__c' {
                        tempMap.put('ParameterId', records[i].get('Id'));
                    }
                    when 'Account_Wise_Product_Target_Line_Item__c', 'Employee_Wise_Product_Target_Line_Item__c' {
                        tempMap.put('ParameterId', records[i].get('Id'));
                    }
                }
                
                if (!res.isSuccess()) {
                    tempMap.put('message', res.getErrors()[0].getMessage());
                    result.put('status', 'PartialError');
                }
                errorList.add(tempMap);
            }
            
            result.put('errorList', errorList);
            return JSON.serialize(result);
        } catch (Exception e) {
            System.debug('Error in saveRecords: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            Map<String, Object> errorResult = new Map<String, Object>();
            errorResult.put('status', 'Error');
            //   errorResult.put('message', e.message);
            return JSON.serialize(errorResult);
        }
    }
    
    private static Decimal parseDecimalSafe(Object value) {
        if (value == null || String.isBlank(String.valueOf(value))) {
            return null;
        }
        try {
            return Decimal.valueOf(String.valueOf(value));
        } catch (Exception e) {
            return null;
        }
    }
    
    
    @AuraEnabled(cacheable = false)
    public static string getTargetQuantityByEmpId(String empId, String fiscId) {
        try {
            List<Employee_Wise_Target__c> ewtList = [
                SELECT Id, Name, Target_Quantity__c, Employee__c
                FROM Employee_Wise_Target__c
                WHERE Employee__c = :empId 
                AND Fiscal_Year__c = :fiscId
                LIMIT 1
            ];
            
            if (!ewtList.isEmpty()) {
                return String.valueOf(ewtList[0].Target_Quantity__c);
            }
            return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = false)
    public static string getTargetQuantityByaccId(String accId, String fiscId, String empId) {
        try {
            List<Employee_Wise_Account_Target__c> ewtList = [
                SELECT Id, Name, Target_Quantity__c, Employee__c, Account__c
                FROM Employee_Wise_Account_Target__c
                WHERE Account__c = :accId
                AND Fiscal_Year__c = :fiscId
                AND Employee__c = :empId
                LIMIT 1
            ];
            
            if (!ewtList.isEmpty()) {
                return String.valueOf(ewtList[0].Target_Quantity__c);
            }
            return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
    
    
    @AuraEnabled(cacheable = false)
    public static string getTargetAmountByEmpId(String empId, String fiscId) {
        try {
            List<Employee_Wise_Target__c> ewtList = [
                SELECT Id, Name, Target_Amount__c, Employee__c
                FROM Employee_Wise_Target__c
                WHERE Employee__c = :empId
                AND Fiscal_Year__c = :fiscId
                LIMIT 1
            ];
            
            if (!ewtList.isEmpty()) {
                return String.valueOf(ewtList[0].Target_Amount__c);
            }
            return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = false)
    public static string getTargetAmountByaccId(String accId, String fiscId, String empId) {
        try {
            List<Employee_Wise_Account_Target__c> ewtList = [
                SELECT Id, Name, Target_Amount__c, Employee__c, Account__c
                FROM Employee_Wise_Account_Target__c
                WHERE Account__c = :accId
                AND Fiscal_Year__c = :fiscId
                AND Employee__c = :empId
                LIMIT 1
            ];
            
            if (!ewtList.isEmpty()) {
                return String.valueOf(ewtList[0].Target_Amount__c);
            }
            return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
    
    
    @AuraEnabled(cacheable = true)
    public static string getProductTargetQtyByProdCatVal(String prodCatVal, String empId, String fiscId) {
        try {
            List<Employee_Wise_Product_Target__c> ewtList = [
                SELECT Id, Name, Target_Quantity__c, Employee__c
                FROM Employee_Wise_Product_Target__c
                WHERE Employee__c = :empId
                AND Product__c = :prodCatVal
                AND Fiscal_Year__c = :fiscId
                LIMIT 1
            ];
            
            if (!ewtList.isEmpty()) {
                return String.valueOf(ewtList[0].Target_Quantity__c);
            }
            return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static string getProductTargetQtyByProdCatValAmt(String prodCatVal, String empId, String accId, String fiscId) {
        try {
            List<Account_Wise_Product_Target__c> ewtList = [
                SELECT Id, Name, Target_Quantity__c, Employee__c, Account__c
                FROM Account_Wise_Product_Target__c
                WHERE Account__c = :accId
                AND Product__c = :prodCatVal
                AND Fiscal_Year__c = :fiscId
                LIMIT 1
            ];
            
            if (!ewtList.isEmpty()) {
                return String.valueOf(ewtList[0].Target_Quantity__c);
            }
            return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static string getProductTargetAmtByProdCatValAmt(String prodCatVal, String empId, String accId, String fiscId) {
        try {
            List<Account_Wise_Product_Target__c> ewtList = [
                SELECT Id, Name, Target_Amount__c, Employee__c, Account__c
                FROM Account_Wise_Product_Target__c
                WHERE Account__c = :accId
                AND Product__c = :prodCatVal
                AND Fiscal_Year__c = :fiscId
                LIMIT 1
            ];
            
            if (!ewtList.isEmpty()) {
                return String.valueOf(ewtList[0].Target_Amount__c);
            }
            return '';
        } catch (Exception e) {
            throw new AuraHandledException(e.getLineNumber() + e.getMessage());
        }
    }
    
}