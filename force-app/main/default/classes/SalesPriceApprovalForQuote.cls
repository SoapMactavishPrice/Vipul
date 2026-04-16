public without sharing class SalesPriceApprovalForQuote {

    public QuoteWrapper quote;

    public SalesPriceApprovalForQuote(QuoteWrapper quote) {
        this.quote = quote;
    }

    @AuraEnabled
    public static List<QuoteWrapper> getAllQuotes() {
        List<QuoteLineItem> allItems = [
            SELECT Id, Product2Id, Product2.Name, QuoteId, ListPrice, UnitPrice, Quantity,
                   Approval_Status__c, Approval_Comments__c, Reject_Reason__c, Approver__c,
                   Product2.ProductCode
            FROM QuoteLineItem
            WHERE Approval_Status__c != 'Approved'
        ];

        // Filter in Apex: UnitPrice < ListPrice
        Map<Id, List<QuoteLineItem>> quoteToItemsMap = new Map<Id, List<QuoteLineItem>>();
        Set<Id> quoteIds = new Set<Id>();

        for (QuoteLineItem item : allItems) {
            if (item.UnitPrice < item.ListPrice) {
                quoteIds.add(item.QuoteId);
                if (!quoteToItemsMap.containsKey(item.QuoteId)) {
                    quoteToItemsMap.put(item.QuoteId, new List<QuoteLineItem>());
                }
                quoteToItemsMap.get(item.QuoteId).add(item);
            }
        }

        if (quoteIds.isEmpty()) {
            throw new AuraHandledException('No Quote Line Items found with Sales Price less than List Price and status "Pending".');
        }

        Map<Id, Quote> quoteMap = new Map<Id, Quote>(
            [SELECT Id, Name, AccountId, Account.Name, OwnerId, Owner.Email, Owner.Name, Link__c, 
                    Who_will_attend__c, Who_will_attend__r.Name, QuoteNumber
             FROM Quote WHERE Id IN :quoteIds]
        );

        List<QuoteWrapper> wrappers = new List<QuoteWrapper>();
        for (Id quoteId : quoteToItemsMap.keySet()) {
            wrappers.add(new QuoteWrapper(quoteMap.get(quoteId), quoteToItemsMap.get(quoteId)));
        }

        return wrappers;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> findRecentPrices(String accountId, String productId) {
        if (String.isEmpty(accountId) || String.isEmpty(productId)) {
            return new List<QuoteLineItem>();
        }
        
        List<QuoteLineItem> qliList = [
            SELECT Id, QuoteId, Product2.Name, UnitPrice, ListPrice, Quantity, CreatedDate, 
                   Quote.Account.Name, Quote.Name, Quote.QuoteNumber
            FROM QuoteLineItem
            WHERE QuoteId IN (SELECT Id FROM Quote WHERE AccountId = :accountId)
            AND Product2Id = :productId
            AND UnitPrice != null
            //AND UnitPrice < ListPrice
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
        return qliList;
    }

    @AuraEnabled
    public static String updateQuoteLineItems(String quoteListStringObject) {
        List<QuoteWrapper> quotes = (List<QuoteWrapper>) JSON.deserialize(quoteListStringObject, List<QuoteWrapper>.class);
        List<QuoteLineItem> itemsToUpdate = new List<QuoteLineItem>();

        for (QuoteWrapper quote : quotes) {
            if (quote.updated && quote.lineItems != null) {
                for (QuoteLineItemWrapper item : quote.lineItems) {
                    if (item.updated) {
                        QuoteLineItem qli = new QuoteLineItem();
                        qli.Id = item.id;
                        qli.Approval_Status__c = item.approvalStatus;
                        qli.Approval_Comments__c = item.approvalComments;
                        qli.UnitPrice = item.salesPrice;
                        itemsToUpdate.add(qli);
                    }
                }
            }
        }

        update itemsToUpdate;

        for (QuoteWrapper quote : quotes) {
            new SalesPriceApprovalForQuote(quote).sendEmailNotification();
        }

        return 'Success';
    }

    private void sendEmailNotification() {
        Boolean isApproved = false;
        Boolean isRejected = false;

        for (QuoteLineItemWrapper item : quote.lineItems) {
            if (item.approvalStatus == 'Approved') {
                isApproved = true;
            } else if (item.approvalStatus == 'Rejected') {
                isRejected = true;
            }
        }

        if (isApproved) sendEmail('Approved');
        if (isRejected) sendEmail('Rejected');
    }

    private void sendEmail(String status) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{quote.ownerEmail});
        email.setCcAddresses(new String[]{'ankit@finessedirect.com'});
        email.setSubject('Sales Price ' + status + ' - ' + quote.name);

        String body = 'Dear ' + quote.ownerName + ',<br/><br/>';
        body += 'The Sales Price has been ' + status.toLowerCase() + ' for the following Quote:<br/><br/>';
        body += 'Quote Name: ' + quote.name + '<br/>';
        body += 'Quote Number: ' + quote.quoteNumber + '<br/>';
        body += 'Quote Link: ' + quote.link + '<br/><br/>';
        body += 'Below are the product details:<br/><br/>';

        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>List Price</th><th>Sales Price</th><th>Approval Status</th></tr></thead><tbody>';

        for (QuoteLineItemWrapper item : quote.lineItems) {
            if (item.approvalStatus == status) {
                body += '<tr>';
                body += '<td>' + item.productName + '</td>';
                body += '<td>' + item.listPrice + '</td>';
                body += '<td>' + item.salesPrice + '</td>';
                body += '<td>' + item.approvalStatus + '</td>';
                body += '</tr>';
            }
        }

        body += '</tbody></table><br/>';
        body += 'Sales Price has been ' + status.toLowerCase() + ', kindly review the details at your earliest convenience.<br/><br/>';
        body += 'Regards,<br/>';
        body += (quote.attendeeName != null ? quote.attendeeName : 'System Notification');

        email.setHtmlBody(body);

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {
            System.debug('Email Sending Failed: ' + e.getMessage());
        }
    }

    public class QuoteWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String quoteNumber;
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String ownerId;
        @AuraEnabled public String ownerEmail;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String link;
        @AuraEnabled public String attendeeName;
        @AuraEnabled public List<QuoteLineItemWrapper> lineItems;
        @AuraEnabled public Boolean updated;

        public QuoteWrapper() {}

        public QuoteWrapper(Quote quote, List<QuoteLineItem> items) {
            this.id = quote.Id;
            this.name = quote.Name;
            this.quoteNumber = quote.QuoteNumber;
            this.accountId = quote.AccountId;
            this.accountName = quote.Account != null ? quote.Account.Name : 'No Account';
            this.ownerId = quote.OwnerId;
            this.ownerEmail = quote.Owner.Email;
            this.ownerName = quote.Owner.Name;
            this.link = quote.Link__c;
            this.attendeeName = quote.Who_will_attend__r != null ? quote.Who_will_attend__r.Name : null;
            this.updated = false;
            this.lineItems = new List<QuoteLineItemWrapper>();

            for (QuoteLineItem item : items) {
                this.lineItems.add(new QuoteLineItemWrapper(item));
            }
        }
    }

    public class QuoteLineItemWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String productId;
        @AuraEnabled public String productName;
        @AuraEnabled public String productCode;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal salesPrice;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String approvalStatus;
        @AuraEnabled public String approvalComments;
        @AuraEnabled public Boolean updated;

        public QuoteLineItemWrapper() {}

        public QuoteLineItemWrapper(QuoteLineItem item) {
            this.id = item.Id;
            this.productId = item.Product2Id;
            this.productName = item.Product2.Name;
            this.productCode = item.Product2.ProductCode;
            this.listPrice = item.ListPrice;
            this.salesPrice = item.UnitPrice;
            this.quantity = item.Quantity;
            this.approvalStatus = item.Approval_Status__c;
            this.approvalComments = item.Approval_Comments__c;
            this.updated = false;
        }
    }
}