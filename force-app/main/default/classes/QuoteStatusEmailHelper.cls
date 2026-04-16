public class QuoteStatusEmailHelper {

    @AuraEnabled
    public static void sendQuoteStatusEmails(List<Id> quoteIds) {
        // Query all quotes and their associated QuoteLineItems, including Product2.Name
        List<Quote> quotes = [SELECT Id, Name, Owner.Email, Owner.Name, Link__c, 
                                       (SELECT Id, Product2.Name, Purchase_Price_Status__c, Reject_Reason__c, Product2Id, Quantity,
                                        Purchase_Price_in_INR__c, LastModifiedDate
                                        FROM QuoteLineItems)
                                   FROM Quote
                                   WHERE Id IN :quoteIds];

        // Loop through each quote
        for (Quote quote : quotes) {
            // Check if the Quote has any QuoteLineItems to process
            if (quote.QuoteLineItems != null && !quote.QuoteLineItems.isEmpty()) {
                // Flags for determining if we need to send email
                Boolean sendEmailForApproved = false;
                Boolean sendEmailForRejected = false;
                List<QuoteLineItem> approvedLineItems = new List<QuoteLineItem>();
                List<QuoteLineItem> rejectedLineItems = new List<QuoteLineItem>();
                String rejectReason = '';

                // Loop through each QuoteLineItem to check if the status has been updated to Approved or Rejected
                for (QuoteLineItem qli : quote.QuoteLineItems) {
                    // Check if the status has changed to Approved or Rejected (only for the current field update)
                    if (qli.Purchase_Price_Status__c == 'Approved') {
                        approvedLineItems.add(qli); // Add the approved line item to the list
                        sendEmailForApproved = true;
                    } 
                    else if (qli.Purchase_Price_Status__c == 'Rejected') {
                        rejectedLineItems.add(qli); // Add the rejected line item to the list
                        rejectReason = qli.Reject_Reason__c;
                        sendEmailForRejected = true;
                    }
                }

                // Send email for approved line items if any
                if (sendEmailForApproved) {
                    // Prepare the email notification
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(new String[] { quote.Owner.Email });
                    email.setToAddresses(new String[] {'ankit@finessedirect.com'}); // Optional CC
                    //email.setToAddresses(new String[]{'dipti.mehta@vipulorganics.com'});
                    email.setWhatId(quote.Id);

                    // Set the email subject based on the status
                    email.setSubject('Purchase Price - Approved - ' + quote.Name);

                    // Build the email body
                    String body = 'Dear ' + quote.Owner.Name + ',<br/><br/>';
                    body += 'The Purchase Price has been approved for the following Quote: ' + quote.Name + '<br/><br/>';

                    // Table of QuoteLineItem details for approved items only
                    body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
                    body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>Quantity</th><th>Purchase Price (INR)</th></tr></thead><tbody>';

                    for (QuoteLineItem qli : approvedLineItems) {
                        body += '<tr>';
                        body += '<td>' + qli.Product2.Name + '</td>';
                        body += '<td>' + qli.Quantity + '</td>';
                        body += '<td>' + (qli.Purchase_Price_in_INR__c != null ? String.valueOf(qli.Purchase_Price_in_INR__c) : 'Not Available') + '</td>';
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
                        System.debug('Email sent successfully to: ' + quote.Owner.Email);
                    } catch (Exception e) {
                        System.debug('Error sending email: ' + e.getMessage());
                    }
                }

                // Send email for rejected line items if any
                if (sendEmailForRejected) {
                    // Prepare the email notification
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    System.debug('Quote Owner Email: ' + quote.Owner.Email);
                     email.setToAddresses(new String[] { quote.Owner.Email });
                     email.setToAddresses(new String[]{'sahil@finessedirect.com'}); // Optional CC
                    //email.setToAddresses(new String[]{'dipti.mehta@vipulorganics.com'});
                    email.setWhatId(quote.Id);

                    // Set the email subject based on the status
                    email.setSubject('Purchase Price - Rejected - ' + quote.Name);

                    // Build the email body
                    String body = 'Dear ' + quote.Owner.Name + ',<br/><br/>';
                    body += 'The Purchase Price has been rejected for the following Quote: ' + quote.Name + '<br/><br/>';
                    body += 'Reason for rejection: ' + (String.isEmpty(rejectReason) ? 'No reason provided' : rejectReason) + '<br/><br/>';

                    // Simple message for re-submission with only one link
                    body += 'Please add the purchase price again: '+ quote.Link__c + '</a><br/><br/>';

                    // Table of QuoteLineItem details for rejected items only
                    body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
                    body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>Quantity</th><th>Purchase Price (INR)</th></tr></thead><tbody>';

                    for (QuoteLineItem qli : rejectedLineItems) {
                        body += '<tr>';
                        body += '<td>' + qli.Product2.Name + '</td>';
                        body += '<td>' + qli.Quantity + '</td>';
                        body += '<td>' + (qli.Purchase_Price_in_INR__c != null ? String.valueOf(qli.Purchase_Price_in_INR__c) : 'Not Available') + '</td>';
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
                        System.debug('Email sent successfully to: ' + quote.Owner.Email);
                    } catch (Exception e) {
                        System.debug('Error sending email: ' + e.getMessage());
                    }
                }
            }
        }
    }
}