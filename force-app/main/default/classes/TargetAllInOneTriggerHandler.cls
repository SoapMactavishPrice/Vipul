public with sharing class TargetAllInOneTriggerHandler {

    public static void rollupTargetAmount(List < sObject > newRecords, Map < Id, sObject > oldMap, String objType) {
        for (sObject obj: newRecords) {
            if (objType == 'EmployeeWiseTarget') {
             /*   if (obj.get('Target_Quantity_Monthly__c') != oldMap.get(obj.Id).get('Target_Quantity_Monthly__c')) {
                    	obj.put('Target_Quantity__c', obj.get('Target_Quantity_Monthly__c'));		
                }		*/
                if (obj.get('Target_Amount_Monthly_Rollup__c') != oldMap.get(obj.Id).get('Target_Amount_Monthly_Rollup__c')) {
                    obj.put('Target_Amount__c', obj.get('Target_Amount_Monthly_Rollup__c'));
                }
            }
            if (objType == 'EmployeeWiseProductTarget' || objType == 'EmployeeWiseAccountTarget' || objType== 'AccountWiseProductTarget' ) {
                if (obj.get('Monthly_Target_Quantity__c') != oldMap.get(obj.Id).get('Monthly_Target_Quantity__c')) {
                    obj.put('Target_Quantity__c', obj.get('Monthly_Target_Quantity__c'));
                }
                if (obj.get('Target_Amount_Monthly_Rollup__c') != oldMap.get(obj.Id).get('Target_Amount_Monthly_Rollup__c')) {
                    obj.put('Target_Amount__c', obj.get('Target_Amount_Monthly_Rollup__c'));
                }
            }
        }
    }

    public static void createMonthlyTargetEntries(List < sObject > newRecords) {
        System.debug('Before' + DataCls.getFiscalYearMaster());
        Map < Id, Fiscal_Year__c > mapFiscalYears = new Map < Id, Fiscal_Year__c > (DataCls.getFiscalYearMaster());
        System.debug('After' + DataCls.getFiscalYearMaster());
        List < sObject > lineItems = new List < sObject > ();

        for (sObject obj: newRecords) {
            Fiscal_Year__c fy = mapFiscalYears.get((Id) obj.get('Fiscal_Year__c'));

            Date dt1 = fy.FY_Start_Date__c.toStartOfMonth();
            system.debug('dt1-->' + dt1);
            if (fy.is_Complete__c) {
                obj.addError('Can\'t create records for old/previous Fiscal Year');
            }
            Date dt2 = fy.FY_End_Date__c;
            Integer monthsInBetween = dt1.toStartOfMonth().monthsBetween(dt2.addDays(1));
            while (dt1 < dt2) {
                sObject lineItem;

                switch on String.valueOf(obj.getSObjectType()) {
                    when 'Employee_Wise_Target__c' {
                        lineItem = new Employee_Wise_Target_Line_Item__c();
                        lineItem.put('Employee_Wise_Target__c', obj.get('Id'));
                        lineItem.put('CurrencyIsoCode', obj.get('CurrencyIsoCode'));
                    }

                    when 'Employee_Wise_Product_Target__c' {
                        lineItem = new Employee_Wise_Product_Target_Line_Item__c();
                        lineItem.put('Employee_Wise_Product_Target__c', obj.get('Id'));
                        lineItem.put('CurrencyIsoCode', obj.get('CurrencyIsoCode'));
                    }

                    when 'Employee_Wise_Account_Target__c' {
                        lineItem = new Employee_Wise_Account_Target_Line_Item__c();
                        lineItem.put('Employee_Wise_Account_Target__c', obj.get('Id'));
                        lineItem.put('CurrencyIsoCode', obj.get('CurrencyIsoCode'));
                    }
                    when 'Account_Wise_Product_Target__c' {
                        lineItem = new Account_Wise_Product_Target_Line_Item__c();
                        lineItem.put('Account_Wise_Product_Target__c', obj.get('Id'));
                        lineItem.put('CurrencyIsoCode', obj.get('CurrencyIsoCode'));
                    }
                }

                lineItem.put('Start_Date__c', dt1);
                lineItem.put('End_Date__c', dt1.addMonths(1) - 1);
                 if ((Date)lineItem.get('End_Date__c') < System.today()) {
                    lineItem.put('Monthly_Target_Amount__c', 0);
                     lineItem.put('Monthly_Target_Quantity__c', 0);
                    monthsInBetween = monthsInBetween - 1;
                } else {
                     Decimal targetQuantity = obj.get('Target_Quantity__c') != null ? (Decimal)obj.get('Target_Quantity__c') : 0;
                    lineItem.put('Monthly_Target_Quantity__c', targetQuantity / monthsInBetween);
                    Decimal targetAmount = obj.get('Target_Amount__c') != null ? (Decimal)obj.get('Target_Amount__c') : 0;
                    lineItem.put('Monthly_Target_Amount__c', targetAmount / monthsInBetween);
                    System.debug(obj.get('Target_Amount__c'));
                    System.debug(targetAmount / monthsInBetween);
                }
                lineItems.add(lineItem);
                dt1 = dt1.addMonths(1);
            }
        }
        system.debug('lineItems->' + lineItems);
        insert lineItems;
    }

    public static void updateMonthlyTargetEntries(List < sObject > newRecords, Map < Id, sObject > oldMap, Map < Id, sObject > newMap, String objType) {
        System.debug('updateMonthlyTargetEntries:>>');
        Set < Id > objIds = new Set < Id > ();
        for (sObject obj: newRecords) {
            Decimal newTargetQuantity = getDecimalValue(obj, 'Target_Quantity__c');
            Decimal oldTargetQuantity = getDecimalValue(oldMap.get(obj.Id), 'Target_Quantity__c');
            Decimal newTargetAmount = getDecimalValue(obj, 'Target_Amount__c');
            Decimal oldTargetAmount = getDecimalValue(oldMap.get(obj.Id), 'Target_Amount__c');

            if (objType == 'EmployeeWiseTarget') {
            /*    if (obj.get('Target_Quantity__c') != oldMap.get(obj.Id).get('Target_Quantity__c') &&
                    obj.get('Target_Quantity__c') != obj.get('Target_Quantity_Monthly__c')) {
                    objIds.add((Id) obj.get('Id'));
                }        */
                if (newTargetAmount != oldTargetAmount &&
                    newTargetAmount != getDecimalValue(obj, 'Target_Amount_Monthly_Rollup__c')) {
                    objIds.add((Id) obj.get('Id'));
                }
            }
            if (objType == 'EmployeeWiseProductTarget' || objType == 'EmployeeWiseAccountTarget' || objType == 'AccountWiseProductTarget' ) {
                if (newTargetQuantity != oldTargetQuantity &&
                    newTargetQuantity != getDecimalValue(obj, 'Monthly_Target_Quantity__c')) {
                    objIds.add((Id) obj.get('Id'));
                }
                if (newTargetAmount != oldTargetAmount &&
                    newTargetAmount != getDecimalValue(obj, 'Target_Amount_Monthly_Rollup__c')) {
                    objIds.add((Id) obj.get('Id'));
                }
            }
        }

        System.debug('objIds:>>>>>>>>> ' + objIds.size());

        if (objIds.size() > 0) {
            Date currentDate = System.today().toStartOfMonth();

            Map < Id, sObject > objMap;
            String sObjectTypeName = String.valueOf(newRecords[0].getSObjectType());

            switch on sObjectTypeName {
                when 'Employee_Wise_Target__c' {
                    objMap = new Map < Id, Employee_Wise_Target__c > (
                        [SELECT Id, Target_Quantity__c, Target_Amount__c,
                            (
                                SELECT Id, Monthly_Target_Quantity__c, Month_Name__c, Monthly_Target_Amount__c FROM Employee_Wise_Target_Line_Items__r WHERE Start_Date__c >=: currentDate ORDER BY Start_Date__c
                            )
                            FROM Employee_Wise_Target__c
                            WHERE Id IN: objIds
                        ]
                    );
                }

                when 'Employee_Wise_Product_Target__c' {
                    objMap = new Map < Id, Employee_Wise_Product_Target__c > (
                        [SELECT Id, Target_Quantity__c, Target_Amount__c,
                            (
                                SELECT Id, Monthly_Target_Quantity__c, Month_Name__c, Monthly_Target_Amount__c FROM Employee_Wise_Product_Target_Line_Items__r WHERE Start_Date__c >=: currentDate ORDER BY Start_Date__c
                            )
                            FROM Employee_Wise_Product_Target__c
                            WHERE Id IN: objIds
                        ]
                    );
                }
                when 'Employee_Wise_Account_Target__c' {
                    objMap = new Map < Id, Employee_Wise_Account_Target__c > (
                        [SELECT Id, Target_Quantity__c, Target_Amount__c,
                            (
                                SELECT Id, Monthly_Target_Quantity__c, Month_Name__c, Monthly_Target_Amount__c FROM Employee_Wise_Account_Target_Line_Item__r WHERE Start_Date__c >=: currentDate ORDER BY Start_Date__c
                            )
                            FROM Employee_Wise_Account_Target__c
                            WHERE Id IN: objIds
                        ]
                    );
                }
                when 'Account_Wise_Product_Target__c' {
                    objMap = new Map < Id, Account_Wise_Product_Target__c > (
                        [SELECT Id, Target_Quantity__c, Target_Amount__c,
                            (
                                SELECT Id, Monthly_Target_Quantity__c, Month_Name__c, Monthly_Target_Amount__c FROM Account_Wise_Product_Target_Line_Item__r WHERE Start_Date__c >=: currentDate ORDER BY Start_Date__c
                            )
                            FROM Account_Wise_Product_Target__c
                            WHERE Id IN: objIds
                        ]
                    );
                }
            }

            List < sObject > objLineItemsForUpdate = new List < sObject > ();
            List < sObject > objLineItemsForUpdate2 = new List < sObject > ();

            for (sObject obj: objMap.values()) {
                Decimal newTargetQuantity = getDecimalValue(obj, 'Target_Quantity__c');
                Decimal oldTargetQuantity = getDecimalValue(oldMap.get(obj.Id), 'Target_Quantity__c');
                Decimal newTargetAmount = getDecimalValue(obj, 'Target_Amount__c');
                Decimal oldTargetAmount = getDecimalValue(oldMap.get(obj.Id), 'Target_Amount__c');

                if (newTargetQuantity != oldTargetQuantity) {
                    List < sObject > childList = getChildLineItems(obj, sObjectTypeName);
                    if (childList.isEmpty()) {
                        addTargetFieldError(newMap, obj.Id, sObjectTypeName, 'Target_Quantity__c',
                            'No child items available to proceed with updating target quantity');
                    } else {
                        Decimal diff = newTargetQuantity - oldTargetQuantity;
                        Decimal diffPerMonth = diff / childList.size();

                        for (sObject childObj: childList) {
                            childObj.put('Monthly_Target_Quantity__c', getDecimalValue(childObj, 'Monthly_Target_Quantity__c') + diffPerMonth);
                            objLineItemsForUpdate.add(childObj);
                        }
                    }
                }

                if (newTargetAmount != oldTargetAmount) {
                    List < sObject > childList = getChildLineItems(obj, sObjectTypeName);
                    if (childList.isEmpty()) {
                        addTargetFieldError(newMap, obj.Id, sObjectTypeName, 'Target_Amount__c',
                            'No child items available to proceed with updating target amount');
                    } else {
                        Decimal diff = newTargetAmount - oldTargetAmount;
                        Decimal diffPerMonth = diff / childList.size();

                        for (sObject childObj: childList) {
                            childObj.put('Monthly_Target_Amount__c', getDecimalValue(childObj, 'Monthly_Target_Amount__c') + diffPerMonth);
                            objLineItemsForUpdate2.add(childObj);
                        }
                    }
                }
            }

            if (objLineItemsForUpdate.size() > 0) {
                System.debug('objLineItemsForUpdate:>> ' + objLineItemsForUpdate.size());
                update objLineItemsForUpdate;
            }
            if (objLineItemsForUpdate2.size() > 0) {
                System.debug('objLineItemsForUpdate2:>> ' + objLineItemsForUpdate2.size());
                update objLineItemsForUpdate2;
            }
        }
    }

    private static Decimal getDecimalValue(sObject record, String fieldName) {
        if (record == null) {
            return 0;
        }

        Object fieldValue = record.get(fieldName);
        if (fieldValue == null) {
            return 0;
        }

        return (Decimal) fieldValue;
    }

    private static List<sObject> getChildLineItems(sObject masterRecord, String sObjectTypeName) {
        List<sObject> childList = new List<sObject>();

        switch on sObjectTypeName {
            when 'Employee_Wise_Target__c' {
                System.debug(JSON.serialize(masterRecord));
                Employee_Wise_Target__c masterObj = (Employee_Wise_Target__c) masterRecord;
                if (masterObj.Employee_Wise_Target_Line_Items__r != null) {
                    childList.addAll(masterObj.Employee_Wise_Target_Line_Items__r);
                }
            }
            when 'Employee_Wise_Product_Target__c' {
                Employee_Wise_Product_Target__c masterObj = (Employee_Wise_Product_Target__c) masterRecord;
                if (masterObj.Employee_Wise_Product_Target_Line_Items__r != null) {
                    childList.addAll(masterObj.Employee_Wise_Product_Target_Line_Items__r);
                }
            }
            when 'Employee_Wise_Account_Target__c' {
                Employee_Wise_Account_Target__c masterObj = (Employee_Wise_Account_Target__c) masterRecord;
                if (masterObj.Employee_Wise_Account_Target_Line_Item__r != null) {
                    childList.addAll(masterObj.Employee_Wise_Account_Target_Line_Item__r);
                }
            }
            when 'Account_Wise_Product_Target__c' {
                Account_Wise_Product_Target__c masterObj = (Account_Wise_Product_Target__c) masterRecord;
                if (masterObj.Account_Wise_Product_Target_Line_Item__r != null) {
                    childList.addAll(masterObj.Account_Wise_Product_Target_Line_Item__r);
                }
            }
        }

        return childList;
    }

    private static void addTargetFieldError(Map<Id, sObject> newMap, Id recordId, String sObjectTypeName, String fieldName, String errorMessage) {
        switch on sObjectTypeName {
            when 'Employee_Wise_Target__c' {
                if (fieldName == 'Target_Quantity__c') {
                    ((Employee_Wise_Target__c) newMap.get(recordId)).Target_Quantity__c.addError(errorMessage);
                } else {
                    ((Employee_Wise_Target__c) newMap.get(recordId)).Target_Amount__c.addError(errorMessage);
                }
            }
            when 'Employee_Wise_Product_Target__c' {
                if (fieldName == 'Target_Quantity__c') {
                    ((Employee_Wise_Product_Target__c) newMap.get(recordId)).Target_Quantity__c.addError(errorMessage);
                } else {
                    ((Employee_Wise_Product_Target__c) newMap.get(recordId)).Target_Amount__c.addError(errorMessage);
                }
            }
            when 'Employee_Wise_Account_Target__c' {
                if (fieldName == 'Target_Quantity__c') {
                    ((Employee_Wise_Account_Target__c) newMap.get(recordId)).Target_Quantity__c.addError(errorMessage);
                } else {
                    ((Employee_Wise_Account_Target__c) newMap.get(recordId)).Target_Amount__c.addError(errorMessage);
                }
            }
            when 'Account_Wise_Product_Target__c' {
                if (fieldName == 'Target_Quantity__c') {
                    ((Account_Wise_Product_Target__c) newMap.get(recordId)).Target_Quantity__c.addError(errorMessage);
                } else {
                    ((Account_Wise_Product_Target__c) newMap.get(recordId)).Target_Amount__c.addError(errorMessage);
                }
            }
        }
    }

    // Master - Share records with respective parameter
    public static void shareRecordWithUser(List < sObject > newRecords, Map < Id, sObject > oldMap) {
        List < Id > compIds = new List < Id > ();
        Set < Id > itemGroupIds = new Set < Id > ();
        Set < Id > recIds = new Set < Id > ();
        Set < String > recordObjectNames = new Set < String > ();

        for (sObject rec: newRecords) {
            recordObjectNames.add(String.valueOf(rec.getSObjectType()).replace('__c', '__Share'));
            switch on String.valueOf(rec.getSObjectType()) {
                when 'Employee_Wise_Target__c', 'Employee_Wise_Product_Target__c', 'Employee_Wise_Account_Target__c','Account_Wise_Product_Target__c' {
                    // Will be sharing with the User only so not collecting Ids from the records
                }

            }
        }

        Map < Id, Id > mapParentToCompany = new Map < Id, Id > ();
        Map < Id, Id > mapParentToItemGroup = new Map < Id, Id > ();

        if (itemGroupIds.size() > 0) {
            for (Item_Group_Master__Share rec: [SELECT ParentId, UserOrGroupId FROM Item_Group_Master__Share WHERE ParentId IN: itemGroupIds]) {
                mapParentToItemGroup.put(rec.ParentId, rec.UserOrGroupId);
            }
        }

        List < sObject > shareRecords = new List < sObject > ();
        for (sObject rec: newRecords) {
            String recObjectName = String.valueOf(rec.getSObjectType()).replace('__c', '__Share');
            Type shareType = Type.forName(recObjectName);
            if (shareType != null) {
                SObject shareRecord = (SObject) shareType.newInstance();
                shareRecord.put('ParentId', rec.Id);
                shareRecord.put('AccessLevel', 'Read');

                switch on String.valueOf(rec.getSObjectType()) {
                    when 'Employee_Wise_Target__c', 'Employee_Wise_Product_Target__c', 'Employee_Wise_Account_Target__c','Account_Wise_Product_Target__c' {
                        shareRecord.put('UserOrGroupId', rec.get('Employee__c'));
                        //shareRecord.put('UserOrGroupId', rec.get('Account__c'));
                    }

                }
                shareRecords.add(shareRecord);
                System.debug(shareRecord);
                System.debug(rec);
            }
        }
        System.debug('shareRecords' + shareRecords);
        if (shareRecords.size() > 0) {
            Database.insert(shareRecords, false);
        }
    }

   /* public static void evaluateValues(List < sObject > newRecords) {
        for (sObject obj: newRecords) {
            Date startDt = (Date) obj.get('Start_Date__c');
            String monthName = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day()).format('MMMM');
            obj.put('Month_Name__c', monthName);
        }
    }  */
    
    public static void evaluateValues(List<sObject> newRecords) {
    for (sObject obj : newRecords) {
        Date startDt = (Date) obj.get('Start_Date__c');
        // Null check to avoid NullPointerException
        if (startDt != null) {
            String monthName = DateTime.newInstance(startDt.year(), startDt.month(), startDt.day()).format('MMMM');
            obj.put('Month_Name__c', monthName);
        } else {
            System.debug('Start_Date__c is null for record: ' + obj.get('Id'));
        }
    }
}

    public static void UpdateAmountValues(List < sObject > newRecords) {
        Set < String > paramTypes = new Set < String > ();
        for (sObject obj: newRecords) {
            paramTypes.add(String.valueOf(obj.getSObjectType()));
        }

        for (String param: paramTypes) {
            Map < Id, Decimal > mapSumAmount = new Map < Id, Decimal > ();
            switch on param {
                when 'Employee_Wise_Target_Line_Item__c' {
                    for (AggregateResult result: [SELECT Employee_Wise_Target_Line_Item__c, SUM(TotalAmount) sumAmt
                            FROM Order
                            WHERE Employee_Wise_Target_Line_Item__c IN: newRecords
                            GROUP BY Employee_Wise_Target_Line_Item__c
                        ]) {
                        mapSumAmount.put((Id) result.get('Employee_Wise_Target_Line_Item__c'), (Decimal) result.get('sumAmt'));
                    }
                }
                when 'Employee_Wise_Product_Target_Line_Item__c' {
                    // for (AggregateResult result: [SELECT Employee_Wise_Product_Target_Line_Item__c, SUM(TotalAmount) sumAmt
                    //         FROM Order
                    //         WHERE Employee_Wise_Product_Target_Line_Item__c IN: newRecords
                    //         GROUP BY Employee_Wise_Product_Target_Line_Item__c
                    //     ]) {
                    //     System.debug('Amount TESTINGG:>> ' + result);
                    //     // mapSumAmount.put((Id) result.get('Employee_Wise_Product_Target_Line_Item__c'), (Decimal) result.get('sumAmt'));
                    // }
                }
            }

            for (sObject emp: newRecords) {
              /*  if (mapSumAmount.containsKey(emp.Id)) {
                    emp.put('Actual_Amount__c', mapSumAmount.get(emp.Id));
                } else {
                    emp.put('Actual_Amount__c', 0);
                }*/
            }
        }
    }
}
