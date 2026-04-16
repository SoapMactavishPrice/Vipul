public class CustomerLedgerQableCallout implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        // Perform the callout
        GetCustomerLedger_FromSAP.getCustomerLedgerData(); // Perform the callout here
    }

}