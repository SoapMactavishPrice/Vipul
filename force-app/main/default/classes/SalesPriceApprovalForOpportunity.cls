public without sharing class SalesPriceApprovalForOpportunity {

    public OpportunityWrapper opportunity;
    
    public SalesPriceApprovalForOpportunity(OpportunityWrapper opportunity) {
        this.opportunity = opportunity;
    }
    
    @AuraEnabled
    public static List<OpportunityWrapper> getAllOpportunities() {
        List<OpportunityLineItem> lineItems = [
            SELECT Id, Name, Product2Id, Product2.Name, ProductCode, OpportunityId, ListPrice, Purchase_Price_in_INR__c, Quantity,
            Purchase_Price_Status__c, Reject_Reason__c, Approver__c, Approval_Status__c, Approval_Comments__c, UnitPrice
            FROM OpportunityLineItem
            WHERE Is_SP_Less_Than_LP__c = TRUE 
            AND Approval_Status__c = 'Pending'
            AND Opportunity.StageName = 'New'  // Added filter for StageName
        ];

        if (lineItems.isEmpty()) {
            throw new AuraHandledException('No Opportunity Line Items found with status "Pending", Sales Price less than List Price, and Opportunity Stage "New".');
        }

        Set<Id> opportunityIds = new Set<Id>();
        for (OpportunityLineItem item : lineItems) {
            opportunityIds.add(item.OpportunityId);
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>(
            [SELECT Id, Name, StageName, Enquiry_Number__c, AccountId, Account.Name, Owner.Email, Owner.Name, Link__c, Who_will_attend__c, Who_will_attend__r.Name 
             FROM Opportunity 
             WHERE Id IN :opportunityIds]
        );

        Map<Id, List<OpportunityLineItem>> oppToLineItemMap = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem item : lineItems) {
            if (!oppToLineItemMap.containsKey(item.OpportunityId)) {
                oppToLineItemMap.put(item.OpportunityId, new List<OpportunityLineItem>());
            }
            oppToLineItemMap.get(item.OpportunityId).add(item);
        }

        List<OpportunityWrapper> wrappers = new List<OpportunityWrapper>();
        for (Id oppId : oppToLineItemMap.keySet()) {
            Opportunity opp = oppMap.get(oppId);
            // Double-check stage name (should already be filtered)
            if (opp.StageName == 'New') {
                OpportunityWrapper wrapper = new OpportunityWrapper(opp, oppToLineItemMap.get(oppId));
                wrappers.add(wrapper);
            }
        }

        if (wrappers.isEmpty()) {
            throw new AuraHandledException('No opportunities with Stage "New" found.');
        }

        return wrappers;
    }
    
    // Rest of the Apex methods remain the same...
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> findRecentPrices(String accountId, String productId) {
        if (String.isEmpty(accountId) || String.isEmpty(productId)) {
            return new List<OpportunityLineItem>();
        }
        
        List<OpportunityLineItem> oliList = [
            SELECT Id, OpportunityId, Product2.Name, UnitPrice, TotalPrice, Quantity, CreatedDate, 
                   Opportunity.Account.Name, Opportunity.Name, ListPrice, Final_Price__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE AccountId = :accountId AND StageName = 'New')
            AND Product2Id = :productId
            AND UnitPrice != null
            ORDER BY CreatedDate DESC
            LIMIT 5
        ];
        return oliList;
    }

    @AuraEnabled
    public static String updateOpportunityLineItems(String opportunityListStringObject) {
        List<OpportunityWrapper> opportunities = parseOpportunityWrapper(opportunityListStringObject);
        List<OpportunityLineItem> itemsToUpdate = new List<OpportunityLineItem>();

        for (OpportunityWrapper opp : opportunities) {
            if (opp.updated && opp.lineItems != null && !opp.lineItems.isEmpty()) {
                for (OpportunityLineItemWrapper item : opp.lineItems) {
                    if (item.updated) {
                        OpportunityLineItem oli = new OpportunityLineItem();
                        oli.Id = item.id;
                        oli.Approval_Status__c = item.approvalStatus;
                        oli.Approval_Comments__c = item.approvalComments;
                        oli.UnitPrice = item.salesPrice;
                        itemsToUpdate.add(oli);
                    }
                }
            }
        }

        update itemsToUpdate;

        for (OpportunityWrapper opp : opportunities) {
            SalesPriceApprovalForOpportunity controller = new SalesPriceApprovalForOpportunity(opp);
            controller.sendEmailNotification();
        }

        return 'Success';
    }

    private void sendEmailNotification() {
        Boolean isApproved = false;
        Boolean isRejected = false;

        for (OpportunityLineItemWrapper item : opportunity.lineItems) {
            if (item.approvalStatus == 'Approved') {
                isApproved = true;
            } else if (item.approvalStatus == 'Rejected') {
                isRejected = true;
            }
        }

        if (isApproved) {
            sendEmail(opportunity, 'Approved');
        }

        if (isRejected) {
            sendEmail(opportunity, 'Rejected');
        }
    }

    private void sendEmail(OpportunityWrapper oppWrapper, String status) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{oppWrapper.ownerEmail});
        email.setCcAddresses(new String[]{'ankit@finessedirect.com'});
        email.setSubject('Sales Price ' + status + ' - ' + oppWrapper.name);

        String body = 'Dear ' + oppWrapper.ownerName + ',<br/><br/>';
        body += 'The Sales Price has been ' + status.toLowerCase() + ' for the following Opportunity:<br/><br/>';
        body += 'Opportunity Name: ' + oppWrapper.name + '<br/>';
        body += 'Opportunity Link: ' + oppWrapper.link + '<br/><br/>';
        body += 'Below are the product details:<br/><br/>';

        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>List Price</th><th>Sales Price</th><th>Approval Status</th></tr></thead><tbody>';

        for (OpportunityLineItemWrapper item : oppWrapper.lineItems) {
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
        body += (oppWrapper.attendeeName != null ? oppWrapper.attendeeName : 'System Notification');

        email.setHtmlBody(body);

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
        } catch (Exception e) {
            System.debug('Email Sending Failed: ' + e.getMessage());
        }
    }

    private static List<OpportunityWrapper> parseOpportunityWrapper(String jsonString) {
        return (List<OpportunityWrapper>) JSON.deserialize(jsonString, List<OpportunityWrapper>.class);
    }

    public class OpportunityWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String enqNo;
        @AuraEnabled public String stageName;
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String ownerId;
        @AuraEnabled public String ownerEmail;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String link;
        @AuraEnabled public String attendeeName;
        @AuraEnabled public List<OpportunityLineItemWrapper> lineItems;
        @AuraEnabled public Boolean updated;

        public OpportunityWrapper() {}

        public OpportunityWrapper(Opportunity opp, List<OpportunityLineItem> items) {
            this.id = opp.Id;
            this.name = opp.Name;
            this.stageName = opp.StageName;
            this.enqNo = opp.Enquiry_Number__c;
            this.accountId = opp.AccountId;
            this.accountName = opp.Account != null ? opp.Account.Name : 'No Account';
            this.ownerId = opp.OwnerId;
            this.ownerEmail = opp.Owner.Email;
            this.ownerName = opp.Owner.Name;
            this.link = opp.Link__c;
            this.attendeeName = opp.Who_will_attend__r != null ? opp.Who_will_attend__r.Name : null;
            this.updated = false;
            this.lineItems = new List<OpportunityLineItemWrapper>();

            for (OpportunityLineItem item : items) {
                this.lineItems.add(new OpportunityLineItemWrapper(item));
            }
        }
    }

    public class OpportunityLineItemWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String productId;
        @AuraEnabled public String productName;
        @AuraEnabled public Decimal listPrice;
        @AuraEnabled public Decimal salesPrice;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public String approvalStatus;
        @AuraEnabled public String approvalComments;
        @AuraEnabled public Boolean updated;

        public OpportunityLineItemWrapper() {}

        public OpportunityLineItemWrapper(OpportunityLineItem item) {
            this.id = item.Id;
            this.productId = item.Product2Id;
            this.productName = item.Product2.Name;
            this.listPrice = item.ListPrice;
            this.salesPrice = item.UnitPrice;
            this.quantity = item.Quantity;
            this.approvalStatus = item.Approval_Status__c;
            this.approvalComments = item.Approval_Comments__c;
            this.updated = false;
        }
    }
}