global class NDANotificationScheduler implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        NDANotificationBatch batch = new NDANotificationBatch();
        Database.executeBatch(batch);
    }
}