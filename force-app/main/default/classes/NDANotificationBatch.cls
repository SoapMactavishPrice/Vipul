global class NDANotificationBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query records where end date is 15 or 30 days before NDA expiry date
        
        Date todayplus = Date.today().addDays(15);
        Date todayplus1 = Date.today().addDays(30);
        
        String query = 'SELECT Id, Name, OwnerId, End_Date__c FROM Document_Detail__c WHERE End_Date__c = :todayplus OR End_Date__c = :todayplus1';
        System.debug('Query >> '+ Database.query(query));
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Document_Detail__c> scope) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Document_Detail__c doc : scope) {
            // Create email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTargetObjectId(doc.OwnerId);
            email.setSubject('NDA Expiry Notification' +Document_Detail__c.Name);
            email.setPlainTextBody('Your NDA is expiring soon. Please take necessary actions.');
            email.setSaveAsActivity(false); // Set saveAsActivity to false
            emails.add(email);
            
            
            // Send notification
            //Notification.sendNotification(doc.OwnerId, 'NDA Expiry Notification', 'Your NDA is expiring soon.');
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