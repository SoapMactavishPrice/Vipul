public class EditPurchasPrice {
    
    public String currentRecID { get; set; }
    public List<OpportunityLineItem> oppList { get; set; }
    public Opportunity opp { get; set; }
    
    public EditPurchasPrice() {
        currentRecID = ApexPages.CurrentPage().getParameters().get('id');
        
        if (currentRecID != null) {
            fetchOpportunity(); 
            oppList = [SELECT Id, Name, Product2Id, Product2.Name, ProductCode, OpportunityId, ListPrice, Previous_Purchase_Price__c, Quality__c, Product2.Application__c,
                             Purchase_Price_in_INR__c, Quantity, Purchase_Price_Status__c, Reject_Reason__c, Request_Purchase_Price__c
                     FROM OpportunityLineItem 
                     WHERE OpportunityId = :currentRecID AND ListPrice = 0]; 
        }
    }
    
    private void fetchOpportunity() {
        opp = [SELECT Id, Name, Owner.Email, OwnerId, Owner.Name, Who_will_attend__c, Who_will_attend__r.Name, Who_will_attend__r.Id, Link__c  
               FROM Opportunity 
               WHERE Id = :currentRecID LIMIT 1];
    }
    
    public PageReference Save() {
        
        List<OpportunityLineItem> accprogList = new List<OpportunityLineItem>();
        Boolean shouldNotify = false;
        
        if (!oppList.isEmpty()) {
            for (OpportunityLineItem op : oppList) {
                if (op.Purchase_Price_in_INR__c != null) {
                    shouldNotify = true;
                }
                if (op.Purchase_Price_Status__c != null) {
                    op.Purchase_Price_Status__c = '';
                }
                accprogList.add(op);
            }
            
            if (!accprogList.isEmpty()) {
                update accprogList;
                
                if (shouldNotify) {
                    sendEmailNotification();
                    sendCustomNotification(opp);
                }
            }            
        }
        
        PageReference pg = new PageReference('/' + currentRecID);
        pg.setRedirect(true);
        return pg;
    }
    
    public PageReference Cancel() {
        PageReference pg = new PageReference('/' + currentRecID);
        pg.setRedirect(true);
        return pg;        
    }  
    
    public void sendEmailNotification() {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{opp.Owner.Email});
        email.setCCAddresses(new String[]{'ankit@finessedirect.com'}); // Example CC
        email.setWhatId(opp.Id);
        email.setSubject('Purchase Price Added - ' + opp.Name);
        
        String body = 'Dear ' + opp.Owner.Name + ',<br/><br/>';
        body += 'The Purchase Price has been added for the following Opportunity:<br/><br/>';
        body += 'Opportunity Name: ' + opp.Name + '<br/>'; 
        body += 'Opportunity Link: <a href="' + opp.Link__c + '">' + opp.Link__c + '</a><br/><br/>';
        body += 'Below are the product details:<br/><br/>';
        
        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>Quantity</th><th>Purchase Price (INR)</th></tr></thead><tbody>';
        
        for (OpportunityLineItem item : oppList) {
            body += '<tr>';
            body += '<td>' + item.Product2.Name + '</td>';
            body += '<td>' + item.Quantity + '</td>';
            body += '<td>' + (item.Purchase_Price_in_INR__c != null ? String.valueOf(item.Purchase_Price_in_INR__c) : 'Not Available') + '</td>';
            body += '</tr>';
        }
        
        body += '</tbody></table><br/>';
        body += 'Kindly review the details at your earliest convenience.<br/><br/>';
        body += 'Regards,<br/>';
        body += (opp.Who_will_attend__c != null ? opp.Who_will_attend__r.Name : 'System Notification');
        
        email.setHtmlBody(body); 
        
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {
            System.debug('Email Sending Failed: ' + e.getMessage());
        }
    }

    private static void sendCustomNotification(Opportunity opp) {
        try {
            List<CustomNotificationType> notificationTypes = [
                SELECT Id
                FROM CustomNotificationType
                WHERE DeveloperName = 'Notification_to_Owner'
                LIMIT 1
            ];
            
            if (notificationTypes.isEmpty()) {
                System.debug('No custom notification type found with DeveloperName: Notification_to_Owner');
                return;
            }
            
            Id notificationTypeId = notificationTypes[0].Id;
            
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Enquiry Purchase Price Alert');
            notification.setBody('Purchase Price has been added to the Products: ' + opp.Name);
            notification.setTargetId(opp.Id);
            notification.setNotificationTypeId(notificationTypeId);
            
            Set<String> recipientIds = new Set<String>{opp.OwnerId};
            if (opp.Who_will_attend__r != null && opp.Who_will_attend__r.Id != null) {
                recipientIds.add(opp.Who_will_attend__r.Id);
            }
            
            notification.send(recipientIds);
            System.debug('Custom notification for Purchase Price sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }
}