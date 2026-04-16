trigger EmployeeWiseTarget on Employee_Wise_Target__c(before insert, after insert, before update, After Update) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        for (Employee_Wise_Target__c obj: Trigger.new) {
            System.debug('CHECKKKKKKKKK 1:>>> ' + obj.Target_Quantity__c);
        }
        TargetAllInOneTriggerHandler.rollupTargetAmount(Trigger.New, Trigger.oldMap, 'EmployeeWiseTarget');
        for (Employee_Wise_Target__c obj: Trigger.new) {
            System.debug('CHECKKKKKKKKK 2:>>> ' + obj.Target_Quantity__c);
        }
    }

    if (Trigger.isBefore && Trigger.isInsert) {
        for (Employee_Wise_Target__c obj: Trigger.new) {
            System.debug('CHECKKKKKKKKK 3:>>> ' + obj.Target_Quantity__c);
        }
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        for (Employee_Wise_Target__c obj: Trigger.new) {
            System.debug('CHECKKKKKKKKK 4:>>> ' + obj.Target_Quantity__c);
        }
        TargetAllInOneTriggerHandler.createMonthlyTargetEntries(Trigger.New);
        for (Employee_Wise_Target__c obj: Trigger.new) {
            System.debug('CHECKKKKKKKKK 5:>>> ' + obj.Target_Quantity__c);
        }
    }

    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        // TargetAllInOneTriggerHandler.updateBranchTarget(Trigger.New, Trigger.oldMap);
        for (Employee_Wise_Target__c obj: Trigger.new) {
            System.debug('CHECKKKKKKKKK 6:>>> ' + obj.Target_Quantity__c);
        }
        TargetAllInOneTriggerHandler.shareRecordWithUser(Trigger.New, Trigger.oldMap);
        for (Employee_Wise_Target__c obj: Trigger.new) {
            System.debug('CHECKKKKKKKKK 7:>>> ' + obj.Target_Quantity__c);
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        for (Employee_Wise_Target__c obj: Trigger.new) {
            System.debug('CHECKKKKKKKKK 8:>>> ' + obj.Target_Quantity__c);
        }
        TargetAllInOneTriggerHandler.updateMonthlyTargetEntries(Trigger.New, Trigger.oldMap, Trigger.newMap, 'EmployeeWiseTarget');
        for (Employee_Wise_Target__c obj: Trigger.new) {
            System.debug('CHECKKKKKKKKK 9:>>> ' + obj.Target_Quantity__c);
        }
    }

}