global class QuoteExpiryNotificationBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query records where quote expiry date is 7 days from today 
   		Date todayplus = Date.today().addDays(7);
        String query = 'SELECT Id, Name, OwnerId, ExpirationDate FROM Quote WHERE ExpirationDate = :todayplus';
        System.debug('Query >> '+ Database.query(query));
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Quote> scope) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Quote quote : scope) {
            // Create email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTargetObjectId(quote.OwnerId);
            email.setSubject('Quote Expiry Notification' +Quote.Name);
            email.setPlainTextBody('Dear Customer,\n\n' +
                                   'This is a reminder that Quote ' + quote.Name +
                                   ' is expiring in 7 days. Please review it.\n\n');
            email.setSaveAsActivity(false); // Set saveAsActivity to false
            emails.add(email);
            
            // Send notification
            //sendNotification(quote.OwnerId, 'Quote Expiry Notification', 'Your quote is expiring soon.');
        }
        
        // Send all emails
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('Batch job finished.');
        // Optional: Add any post-processing logic here
    }
    
}