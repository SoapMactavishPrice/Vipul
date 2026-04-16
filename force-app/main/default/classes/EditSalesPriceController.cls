public class EditSalesPriceController {
    
    public string currentRecID{get;set;}
    public List<OpportunityLineItem> oppList {get;set;}
    public Opportunity opp { get; set; }
    public Id ownerManagerId { get; set; }
    
    public EditSalesPriceController(){
        
        currentRecID = ApexPages.CurrentPage().getparameters().get('id');
        
        if (currentRecID != null) {
            fetchOpportunity(); 
            List<OpportunityLineItem> allOppItems = [SELECT Id, Name, Product2Id, Product2.Name, ProductCode, OpportunityId, ListPrice, Purchase_Price_in_INR__c, Quantity,
                                                     Purchase_Price_Status__c, Reject_Reason__c, Approver__c, Approval_Status__c, Approval_Comments__c, UnitPrice
                                                     FROM OpportunityLineItem 
                                                     WHERE OpportunityId = :currentRecID];
            
            oppList = new List<OpportunityLineItem>();
            for (OpportunityLineItem item : allOppItems) {
                if (item.UnitPrice < item.ListPrice && item.Approval_Status__c != 'Approved') {
                    item.Approver__c = ownerManagerId; // Set Approver__c to Owner.ManagerId
                    oppList.add(item);
                }
            }
        }
    }
    
    // Fetch Opportunity Details with Who_will_attend__c field and Owner's Manager Email
    private void fetchOpportunity() {
        opp = [SELECT Id, Name, Owner.Email, Owner.Name, Owner.ManagerId, Owner.Manager.Email, Who_will_attend__c, Who_will_attend__r.Name, Link__c  
               FROM Opportunity 
               WHERE Id = :currentRecID LIMIT 1];
        ownerManagerId = opp.Owner.ManagerId;
    }
    
    // Save Method
    public PageReference Save() {
        
        List<OpportunityLineItem> accprogList = new List<OpportunityLineItem>();
        
        if (!oppList.isEmpty()) {
            
            for(OpportunityLineItem op:oppList){
                
                if(op.UnitPrice !=null){
                    
                }
                
            }
            update oppList;
            
            sendEmailNotification();  // Send Email Notification
        }
        
        Pagereference pg = new PageReference('/' + currentRecID);
        pg.setRedirect(true);
        return pg;
    }
    
    Public Pagereference Cancel(){
        
        pagereference pg=new pagereference('/'+currentRecID);
        pg.setRedirect(true);
        return pg;        
    }  
    
    // Email Notification Method
    private void sendEmailNotification() {
        // Check if any OpportunityLineItem has Approval_Status__c set to 'Approved' or 'Rejected'
        Boolean isApproved = false;
        Boolean isRejected = false;
        for (OpportunityLineItem item : oppList) {
            if (item.Approval_Status__c == 'Approved') {
                isApproved = true;
            } else if (item.Approval_Status__c == 'Rejected') {
                isRejected = true;
            }
        }
        
        // Send email if the status is 'Approved'
        if (isApproved) {
            sendEmail('Approved');
        }
        
        // Send email if the status is 'Rejected'
        if (isRejected) {
            sendEmail('Rejected');
        }
    }
    
    private void sendEmail(String status) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{opp.Owner.Email});
        email.setCCAddresses(new String[]{'ankit@finessedirect.com'});
        email.setSubject('Sales Price ' + status + ' - ' + opp.Name);
        
        String body = 'Dear ' + opp.Owner.Name + ',<br/><br/>';
        body += 'The Sales Price has been ' + status.toLowerCase() + ' for the following Opportunity:<br/><br/>';
        body += 'Opportunity Name: ' + opp.Name + '<br/>';
        body += 'Opportunity Link: ' + opp.Link__c + '</a><br/><br/>';
        body += 'Below are the product details:<br/><br/>';
        
        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>List Price</th><th>Sales Price</th><th>Approval Status</th></tr></thead><tbody>';
        
        for (OpportunityLineItem item : oppList) {
            if (item.Approval_Status__c == status) {
                body += '<tr>';
                body += '<td>' + item.Product2.Name + '</td>';
                body += '<td>' + (item.ListPrice != null ? String.valueOf(item.ListPrice) : 'Not Available') + '</td>';
                body += '<td>' + (item.UnitPrice != null ? String.valueOf(item.UnitPrice) : 'Not Available') + '</td>';
                body += '<td>' + (item.Approval_Status__c != null ? String.valueOf(item.Approval_Status__c):'') + '</td>';
                body += '</tr>';
            }
        }
        
        body += '</tbody></table><br/>';
        body += 'Sales Price has been ' + status.toLowerCase() + ', kindly review the details at your earliest convenience.<br/><br/>';
        body += 'Regards,<br/>';
        body += (opp.Who_will_attend__c != null ? opp.Who_will_attend__r.Name : 'System Notification');
        
        email.setHtmlBody(body);
        
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {
            System.debug('Email Sending Failed: ' + e.getMessage());
        }
    }
    
    /*private void sendEmailToManager() {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{opp.Owner.Manager.Email});
        email.setCCAddresses(new String[]{'ankit@finessedirect.com'});
        email.setSubject('Sales Price Alert - ' + opp.Name);
        
        String body = 'Dear Manager,<br/><br/>';
        body += 'The Sales Price for the following Opportunity is lower than the List Price:<br/><br/>';
        body += 'Opportunity Name: ' + opp.Name + '<br/>';
        body += 'Opportunity Link: ' + opp.Link__c + '</a><br/><br/>';
        body += 'Below are the product details:<br/><br/>';
        
        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>List Price</th><th>Sales Price</th></tr></thead><tbody>';
        
        for (OpportunityLineItem item : oppList) {
            body += '<tr>';
            body += '<td>' + item.Product2.Name + '</td>';
            body += '<td>' + (item.ListPrice != null ? String.valueOf(item.ListPrice) : 'Not Available') + '</td>';
            body += '<td>' + (item.UnitPrice != null ? String.valueOf(item.UnitPrice) : 'Not Available') + '</td>';
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
    }*/
}