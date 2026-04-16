public class SendPurchasePriceEmailAsync {

    @future(callout=false)
    public static void sendEmailAsync(String opportunityWrapperJson) {
        OpportunityWrapper opp = (OpportunityWrapper) JSON.deserialize(opportunityWrapperJson, OpportunityWrapper.class);

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{opp.ownerEmail});
        //email.setCcAddresses(new String[]{'ankit@finessedirect.com'});
        email.setSubject('Purchase Price Added - ' + opp.name);

        String body = 'Dear ' + opp.ownerName + ',<br/><br/>';
        body += 'The Purchase Price has been added for the following Opportunity:<br/><br/>';
        body += 'Enquiry Name: ' + opp.name + '<br/>';
        body += 'Enquiry Link: ' + opp.link + '</a><br/><br/>';
        body += 'Below are the product details:<br/><br/>';

        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>Quantity</th><th>Purchase Price (INR)</th></tr></thead><tbody>';

        for (OpportunityLineItemWrapper item : opp.lineItems) {
            body += '<tr>';
            body += '<td>' + item.productName + '</td>';
            body += '<td>' + item.quantity + '</td>';
            body += '<td>' + (item.purchasePrice != null ? String.valueOf(item.purchasePrice) : 'Not Available') + '</td>';
            body += '</tr>';
        }

        body += '</tbody></table><br/>';
        body += 'Kindly review the details at your earliest convenience.<br/><br/>';
        body += 'Regards,<br/>';
        body += (opp.attendeeName != null ? opp.attendeeName : 'System Notification');

        email.setHtmlBody(body);

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {
            System.debug('Email Sending Failed: ' + e.getMessage());
        }
    }

    public class OpportunityWrapper {
        public String id;
        public String name;
        public String ownerEmail;
        public String ownerName;
        public String link;
        public String attendeeName;
        public List<OpportunityLineItemWrapper> lineItems;
    }

    public class OpportunityLineItemWrapper {
        public String productName;
        public Decimal quantity;
        public Decimal purchasePrice;
    }
}