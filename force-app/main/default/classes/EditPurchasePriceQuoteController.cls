public class EditPurchasePriceQuoteController {
    
    public String currentRecID { get; set; }
    public List<QuoteLineItem> quoteList { get; set; }
    public Quote quote { get; set; }
    
    public EditPurchasePriceQuoteController() {
        currentRecID = ApexPages.CurrentPage().getParameters().get('id');
        
        if (currentRecID != null) {
            fetchQuote(); 
            quoteList = [SELECT Id, Product2Id, Product2.Name, QuoteId, ListPrice, Previous_Purchase_Price__c, Quality__c, Product2.Application__c,
                             Purchase_Price_in_INR__c, Quantity, Purchase_Price_Status__c, Reject_Reason__c, Request_Purchase_Price__c
                     FROM QuoteLineItem 
                     WHERE QuoteId = :currentRecID AND ListPrice = 0]; 
        }
    }
    
    private void fetchQuote() {
        quote = [SELECT Id, Name, Owner.Email, OwnerId, Owner.Name, Who_will_attend__c, Who_will_attend__r.Name, Who_will_attend__r.Id, Link__c  
               FROM Quote 
               WHERE Id = :currentRecID LIMIT 1];
    }
    
    public PageReference Save() {
        
        List<QuoteLineItem> quoteLineItemList = new List<QuoteLineItem>();
        Boolean shouldNotify = false;
        
        if (!quoteList.isEmpty()) {
            for (QuoteLineItem ql : quoteList) {
                if (ql.Purchase_Price_in_INR__c != null) {
                    shouldNotify = true;
                }
                if (ql.Purchase_Price_Status__c != null) {
                    ql.Purchase_Price_Status__c = '';
                }
                quoteLineItemList.add(ql);
            }
            
            if (!quoteLineItemList.isEmpty()) {
                update quoteLineItemList;
                
                if (shouldNotify) {
                    sendEmailNotification();
                    sendCustomNotification(quote);
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
    
    private void sendEmailNotification() {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{quote.Owner.Email});
        email.setCCAddresses(new String[]{'ankit@finessedirect.com'}); // Example CC
        email.setWhatId(quote.Id);
        email.setSubject('Purchase Price Added - ' + quote.Name);
        
        String body = 'Dear ' + quote.Owner.Name + ',<br/><br/>';
        body += 'The Purchase Price has been added for the following Quote:<br/><br/>';
        body += 'Quote Name: ' + quote.Name + '<br/>'; 
        body += 'Quote Link: <a href="' + quote.Link__c + '">' + quote.Link__c + '</a><br/><br/>';
        body += 'Below are the product details:<br/><br/>';
        
        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>Quantity</th><th>Purchase Price (INR)</th></tr></thead><tbody>';
        
        for (QuoteLineItem item : quoteList) {
            body += '<tr>';
            body += '<td>' + item.Product2.Name + '</td>';
            body += '<td>' + item.Quantity + '</td>';
            body += '<td>' + (item.Purchase_Price_in_INR__c != null ? String.valueOf(item.Purchase_Price_in_INR__c) : 'Not Available') + '</td>';
            body += '</tr>';
        }
        
        body += '</tbody></table><br/>';
        body += 'Kindly review the details at your earliest convenience.<br/><br/>';
        body += 'Regards,<br/>';
        body += (quote.Who_will_attend__c != null ? quote.Who_will_attend__r.Name : 'System Notification');
        
        email.setHtmlBody(body);
        
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {
            System.debug('Email Sending Failed: ' + e.getMessage());
        }
    }

    private static void sendCustomNotification(Quote quote) {
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
            notification.setTitle('Quote Purchase Price Alert');
            notification.setBody('Purchase Price has been added to the Products: ' + quote.Name);
            notification.setTargetId(quote.Id);
            notification.setNotificationTypeId(notificationTypeId);
            
            Set<String> recipientIds = new Set<String>{quote.OwnerId};
            if (quote.Who_will_attend__r != null && quote.Who_will_attend__r.Id != null) {
                recipientIds.add(quote.Who_will_attend__r.Id);
            }
            
            notification.send(recipientIds);
            System.debug('Custom notification for Quote Purchase Price sent successfully.');
        } catch (Exception e) {
            System.debug('Error sending custom notification: ' + e.getMessage());
        }
    }
}