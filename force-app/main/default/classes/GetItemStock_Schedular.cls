public class GetItemStock_Schedular implements Schedulable {
    
    // Runs when scheduled
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new ItemStockQableCallout());
    }

    // Utility method: schedule job every 5 minutes
    public static void scheduleEvery5Minutes() {
        for (Integer i = 0; i < 60; i += 5) {
            String jobName = 'GetItemStock_' + i;
            String cron = '0 ' + i + ' * * * ?';
            System.schedule(jobName, cron, new GetItemStock_Schedular());
        }
    }
}