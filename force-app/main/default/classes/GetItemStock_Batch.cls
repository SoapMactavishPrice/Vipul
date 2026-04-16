global class GetItemStock_Batch implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts, Schedulable {
    
    global database.QueryLocator start(database.BatchableContext bc) {

        string todayDate = Datetime.now().format();

        if (Test.isRunningTest()) {
            return database.getQueryLocator([
                SELECT Id, Item_No__c, Name
                FROM Product2
                WHERE Item_No__c != null
                ORDER BY Name
                LIMIT 1
            ]);
        } else {
            return database.getQueryLocator([
                SELECT Id, Item_No__c, Name
                FROM Product2
                WHERE Item_No__c != null
                ORDER BY Name
                LIMIT 1
            ]);
        }
    }

    global void Execute(database.BatchableContext bc, List < Product2 > scope) {

        List<Product2> productMappingList = new List<Product2>();
        productMappingList.addAll(scope);

        if (!productMappingList.isEmpty()) {
            // Start processing the first invoice using Queueable
            // System.enqueueJob(new ItemStockQableCallout(productMappingList, 0));
            GetItemStock_FromSAP.getItemStockData();
        }

    }

    global void finish(Database.BatchableContext BC) {}

    // Implement Schedulable
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new GetItemStock_Batch(), 1); // Set batch size to 1
    }

}