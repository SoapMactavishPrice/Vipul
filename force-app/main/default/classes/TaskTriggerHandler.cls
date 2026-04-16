public class TaskTriggerHandler {
    
     public static void updateLeadStatus(List<Task> tasks) {
        System.debug('Handler updateLeadStatus started');
        Set<Id> leadIds = new Set<Id>();

        for (Task t : tasks) {
            System.debug('Processing Task: ' + t);
            System.debug('Task WhatId: ' + t.WhatId);
            System.debug('Task WhoId: ' + t.WhoId);
            System.debug('Task Subject: ' + t.Subject);
            if (t.WhoId != null && t.WhoId.getSObjectType() == Lead.SObjectType) {
                System.debug('Task matches criteria: ' + t.Subject);
                leadIds.add(t.WhoId);
            }
        }

        System.debug('Lead IDs to update: ' + leadIds);

        if (!leadIds.isEmpty()) {
            List<Lead> leadsToUpdate = [SELECT Id, Status FROM Lead WHERE Id IN :leadIds];
            for (Lead lead : leadsToUpdate) {
                System.debug('Updating Lead: ' + lead.Id);
                lead.Status = 'Contacted';
                lead.Task_Count__c = 1;
            }
            update leadsToUpdate;
            System.debug('Leads updated');
        }

        System.debug('Handler updateLeadStatus ended');
    }
}