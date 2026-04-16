public class ItemStockQableCallout implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        // Perform the callout
        GetItemStock_FromSAP.getItemStockData(); // Perform the callout here
    }

}