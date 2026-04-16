trigger UpdateRevisionNumber on QuoteLineItem (after update) {
    Set<Id> quoteIds = new Set<Id>();

    for (QuoteLineItem qli : Trigger.new) {
        QuoteLineItem oldQli = Trigger.oldMap.get(qli.Id);
        if (qli.UnitPrice != oldQli.UnitPrice || qli.Quantity != oldQli.Quantity) {
            quoteIds.add(qli.QuoteId);
        }
    }

    if (quoteIds.isEmpty()) {
        return;
    }

    List<Quote> quotesToUpdate = [SELECT Id, Revision_Number__c FROM Quote WHERE Id IN :quoteIds];

    for (Quote quote : quotesToUpdate) {
        if (quote.Revision_Number__c == null) {
            quote.Revision_Number__c = 1;
        } else {
            quote.Revision_Number__c = quote.Revision_Number__c + 1;
        }
    }

    update quotesToUpdate;
}