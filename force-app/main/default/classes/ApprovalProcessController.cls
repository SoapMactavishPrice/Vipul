public with sharing class ApprovalProcessController {
    
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getPendingApprovals() {
        return [SELECT Id, Opportunity.Name, TotalPrice, UnitPrice, PricebookEntry.Product2.Name, ListPrice
                FROM OpportunityLineItem 
                WHERE Approval_Status__c = 'Pending'];
    }

    @AuraEnabled
    public static void updateApprovalStatus(Id recordId, String status) {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem WHERE Id = :recordId LIMIT 1];
        oli.Approval_Status__c = status;
        update oli;
    }
}