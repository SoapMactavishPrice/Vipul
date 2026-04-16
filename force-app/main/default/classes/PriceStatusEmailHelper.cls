public class PriceStatusEmailHelper {

    @AuraEnabled
    public static void sendPriceStatusEmails(List<Id> oppIds) {
        // Query all opportunities and their associated OpportunityLineItems, including Product2.Name
        List<Opportunity> opportunities = [SELECT Id, Name, Owner.Email, Owner.Name, Link__c, 
                                               (SELECT Id, Product2.Name, Purchase_Price_Status__c, Reject_Reason__c, Product2Id, Quantity,
                                                Purchase_Price_in_INR__c, LastModifiedDate
                                                FROM OpportunityLineItems)
                                           FROM Opportunity
                                           WHERE Id IN :oppIds];

        // Loop through each opportunity
        for (Opportunity opp : opportunities) {
            // Check if the Opportunity has any OpportunityLineItems to process
            if (opp.OpportunityLineItems != null && !opp.OpportunityLineItems.isEmpty()) {
                // Flags for determining if we need to send email
                Boolean sendEmailForApproved = false;
                Boolean sendEmailForRejected = false;
                List<OpportunityLineItem> approvedLineItems = new List<OpportunityLineItem>();
                List<OpportunityLineItem> rejectedLineItems = new List<OpportunityLineItem>();
                String rejectReason = '';

                // Check Purchase Price Status for OpportunityLineItems
                for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                    if (oli.Purchase_Price_Status__c == 'Approved') {
                        approvedLineItems.add(oli); // Add the approved line item to the list
                        sendEmailForApproved = true;
                    } else if (oli.Purchase_Price_Status__c == 'Rejected') {
                        rejectedLineItems.add(oli); // Add the rejected line item to the list
                        rejectReason = oli.Reject_Reason__c;
                        sendEmailForRejected = true;
                    }
                }

                // Send email for approved line items if any
                if (sendEmailForApproved) {
                    // Prepare the email notification
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] { opp.Owner.Email });
                     email.setToAddresses(new String[]{'ankit@finessedirect.com'}); // Optional CC
                    //email.setToAddresses(new String[]{'dipti.mehta@vipulorganics.com'}); 
                    email.setWhatId(opp.Id);

                    // Set the email subject based on the status
                    email.setSubject('Purchase Price - Approved - ' + opp.Name);

                    // Build the email body
                    String body = 'Dear ' + opp.Owner.Name + ',<br/><br/>';
                    body += 'The Purchase Price has been approved for the following Opportunity: ' + opp.Name + '<br/><br/>';

                    // Table of OpportunityLineItem details for approved items only
                    body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
                    body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>Quantity</th><th>Purchase Price (INR)</th></tr></thead><tbody>';

                    for (OpportunityLineItem oli : approvedLineItems) {
                        body += '<tr>';
                        body += '<td>' + oli.Product2.Name + '</td>';
                        body += '<td>' + oli.Quantity + '</td>';
                        body += '<td>' + (oli.Purchase_Price_in_INR__c != null ? String.valueOf(oli.Purchase_Price_in_INR__c) : 'Not Available') + '</td>';
                        body += '</tr>';
                    }

                    body += '</tbody></table><br/>';
                    body += 'Kindly review the details at your earliest convenience.<br/><br/>';
                    body += 'Regards,<br/>';
                    body += 'System Notification';

                    // Set the HTML body for the email
                    email.setHtmlBody(body);

                    try {
                        // Send the email
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                        System.debug('Email sent successfully to: ' + opp.Owner.Email);
                    } catch (Exception e) {
                        System.debug('Error sending email: ' + e.getMessage());
                    }
                }

                // Send email for rejected line items if any
                if (sendEmailForRejected) {
                    // Prepare the email notification
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] { opp.Owner.Email });
                    email.setCCAddresses(new String[]{'ankit@finessedirect.com'}); // Optional CC
                    //email.setCCAddresses(new String[]{'dipti.mehta@vipulorganics.com'}); // Optional CC
                    email.setWhatId(opp.Id);

                    // Set the email subject based on the status
                    email.setSubject('Purchase Price - Rejected - ' + opp.Name);

                    // Build the email body
                    String body = 'Dear ' + opp.Owner.Name + ',<br/><br/>';
                    body += 'The Purchase Price has been rejected for the following Opportunity: ' + opp.Name + '<br/><br/>';
                    body += 'Reason for rejection: ' + (String.isEmpty(rejectReason) ? 'No reason provided' : rejectReason) + '<br/><br/>';

                    // Simple message for re-submission with only one link
                    body += 'Please add the purchase price again: '+ opp.Link__c + '</a><br/><br/>';

                    // Table of OpportunityLineItem details for rejected items only
                    body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
                    body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>Quantity</th><th>Purchase Price (INR)</th></tr></thead><tbody>';

                    for (OpportunityLineItem oli : rejectedLineItems) {
                        body += '<tr>';
                        body += '<td>' + oli.Product2.Name + '</td>';
                        body += '<td>' + oli.Quantity + '</td>';
                        body += '<td>' + (oli.Purchase_Price_in_INR__c != null ? String.valueOf(oli.Purchase_Price_in_INR__c) : 'Not Available') + '</td>';
                        body += '</tr>';
                    }

                    body += '</tbody></table><br/>';
                    body += 'Kindly review the details at your earliest convenience.<br/><br/>';
                    body += 'Regards,<br/>';
                    body += 'System Notification';

                    // Set the HTML body for the email
                    email.setHtmlBody(body);

                    try {
                        // Send the email
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                        System.debug('Email sent successfully to: ' + opp.Owner.Email);
                    } catch (Exception e) {
                        System.debug('Error sending email: ' + e.getMessage());
                    }
                }
            }
        }
    }
}