trigger updatepurchaseprice on OpportunityLineItem (after insert) {
    
   /* Set<Id> opportunityIds = new Set<Id>();
    
    // Collect all OpportunityIds from the new OpportunityLineItems
    for (OpportunityLineItem oli : Trigger.new) {
        opportunityIds.add(oli.OpportunityId); 
    }

    if (!opportunityIds.isEmpty()) {
        // Query for Opportunity details including the OpportunityLineItems and UnitPrice field
        List<Opportunity> opportunitiesToUpdate = [
            SELECT Id, OwnerId, Owner.Email, Owner.Name, Name, Link__c, 
                   Who_will_attend__r.Email, Who_will_attend__r.Name,
                   (SELECT Product2.Name, UnitPrice FROM OpportunityLineItems)
            FROM Opportunity 
            WHERE Id IN :opportunityIds
        ];

        // Iterate over the opportunities and call sendEmailNotification method
        for (Opportunity opp : opportunitiesToUpdate) {
            // Call the sendEmailNotification method with the Opportunity Id
            SendEmail.sendEmailNotification(opp);  
        }
    } */
}