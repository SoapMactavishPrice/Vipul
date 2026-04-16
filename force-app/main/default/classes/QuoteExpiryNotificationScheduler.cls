global class QuoteExpiryNotificationScheduler implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        QuoteExpiryNotificationBatch batch = new QuoteExpiryNotificationBatch();
        Database.executeBatch(batch);
    }
}