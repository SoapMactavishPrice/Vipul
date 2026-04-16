public class ContentDocumentLinkHandler {
    public static void handleAfterInsert(List<ContentDocumentLink> newLinks) {
        Set<Id> sampleInIds = new Set<Id>();
        Set<Id> sampleOutIds = new Set<Id>();
        
        for (ContentDocumentLink cdl : newLinks) {
            if (cdl.LinkedEntityId != null) {
                String sObjType = String.valueOf(cdl.LinkedEntityId.getSObjectType());
                if (sObjType == 'Sample_In__c') {
                    sampleInIds.add(cdl.LinkedEntityId);
                } else if (sObjType == 'Sample_Out__c') {
                    sampleOutIds.add(cdl.LinkedEntityId);
                }
            }
        }
        
        Map<Id, Id> childToParentMap = new Map<Id, Id>();
        Set<Id> parentRequestIds = new Set<Id>();
        
        if (!sampleInIds.isEmpty()) {
            for (Sample_In__c si : [
                SELECT Id, Sample_In_Request__c
                FROM Sample_In__c
                WHERE Id IN :sampleInIds
            ]) {
                if (si.Sample_In_Request__c != null) {
                    childToParentMap.put(si.Id, si.Sample_In_Request__c);
                    parentRequestIds.add(si.Sample_In_Request__c);
                }
            }
        }
        
        if (!sampleOutIds.isEmpty()) {
            for (Sample_Out__c so : [
                SELECT Id, Sample_Out_Request__c
                FROM Sample_Out__c
                WHERE Id IN :sampleOutIds
            ]) {
                if (so.Sample_Out_Request__c != null) {
                    childToParentMap.put(so.Id, so.Sample_Out_Request__c);
                    parentRequestIds.add(so.Sample_Out_Request__c);
                }
            }
        }
        
        // Map parent request to Account (Company_Name__c)
        Map<Id, Id> parentToAccountMap = new Map<Id, Id>();
        for (Sample_In_Request__c sir : [
            SELECT Id, Company_Name__c
            FROM Sample_In_Request__c
            WHERE Id IN :parentRequestIds
        ]) {
            if (sir.Company_Name__c != null) {
                parentToAccountMap.put(sir.Id, sir.Company_Name__c);
            }
        }
        
        
        for (Sample_Out_Request__c sor : [
            SELECT Id, Company_Name__c
            FROM Sample_Out_Request__c
            WHERE Id IN :parentRequestIds
        ]) {
            if (sor.Company_Name__c != null) {
                parentToAccountMap.put(sor.Id, sor.Company_Name__c);
            }
        }
        
        
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
        
        for (ContentDocumentLink cdl : newLinks) {
            Id parentId = childToParentMap.get(cdl.LinkedEntityId);
            if (parentId != null) {
                linksToInsert.add(new ContentDocumentLink(
                    ContentDocumentId = cdl.ContentDocumentId,
                    LinkedEntityId = parentId,
                    ShareType = 'V',
                    Visibility = cdl.Visibility
                ));
                
                Id accountId = parentToAccountMap.get(parentId);
                if (accountId != null) {
                    linksToInsert.add(new ContentDocumentLink(
                        ContentDocumentId = cdl.ContentDocumentId,
                        LinkedEntityId = accountId,
                        ShareType = 'V',
                        Visibility = cdl.Visibility
                    ));
                }
            }
        }
        
        if (!linksToInsert.isEmpty()) {
            insert linksToInsert;
        }
    }
}