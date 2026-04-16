global class GetCustomerLedger_Batch implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts, Schedulable {
    
    global database.QueryLocator start(database.BatchableContext bc) {

        string todayDate = Datetime.now().format();

        if (Test.isRunningTest()) {
            return database.getQueryLocator([
                SELECT Id, Customer_Code__c, Name
                FROM Account
                WHERE Customer_Code__c != null
                ORDER BY Name
                LIMIT 1
            ]);
        } else {
            return database.getQueryLocator([
                SELECT Id, Customer_Code__c, Name
                FROM Account
                WHERE Customer_Code__c != null
                // WHERE Customer_Code__c IN ('CD0000220','CI0000854')
                // ORDER BY Name
                LIMIT 1
            ]);
        }
    }

    global void Execute(database.BatchableContext bc, List < Account > scope) {

        List<Account> accMappingList = new List<Account>();
        accMappingList.addAll(scope);

        if (!accMappingList.isEmpty()) {
            // Start processing the first invoice using Queueable
            // System.enqueueJob(new CustomerLedgerQableCallout(accMappingList, 0));
            GetCustomerLedger_FromSAP.getCustomerLedgerData();
        }

    }

    global void finish(Database.BatchableContext BC) {}

    // Implement Schedulable
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new GetCustomerLedger_Batch(), 1); // Set batch size to 1
    }

}