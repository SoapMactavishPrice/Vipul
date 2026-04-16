public class GetCustomerLedger_Schedular implements Schedulable {

    // Runs when scheduled
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new CustomerLedgerQableCallout());
    }

    // Utility method: schedule job every 5 minutes
    public static void scheduleEvery5Minutes() {
        for (Integer i = 0; i < 60; i += 5) {
            String jobName = 'GetCustomerLedger_' + i;
            String cron = '0 ' + i + ' * * * ?';
            System.schedule(jobName, cron, new GetCustomerLedger_Schedular());
        }
    }
}