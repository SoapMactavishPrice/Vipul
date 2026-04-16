public without sharing class  SendTDSFile {
    
    @AuraEnabled 
    public static string getEmailDetails(string oppId){
        Opportunity opp = [select Id,AccountId,Contact__c  from Opportunity where Id =:oppId limit 1];   
        List<Account> accList =[select Id,(Select Id,Email from Contacts) from Account where Id =:opp.AccountId];  
        string key = 'cc';
        map<string,Set<String>> str = new map<string,Set<String>>();
        for(Account acc : accList){
            
             for(Contact con :acc.Contacts){
                
                if(con.Id == opp.Contact__c){
                     str.put('ToAdd',new Set<String>{con.Email});
                 } else {
                    
                     if(str.containskey(key)){
                         str.get(key).add(con.Email); 
                     }else{
                         str.put(key,new Set<String>{con.Email}); 
                     }
                 }
             }
        }
        
        if(str.size() > 0)
            system.debug('-->'+JSON.serialize(str));
        
        if(str.size() > 0)
            
            return JSON.serialize(str);
        else 
            return null;
    }
    
    @AuraEnabled
    public static string getProductData (string oppId){
        system.debug('oppId'+oppId);
        List<OpportunityLineItem> opliList = [select Id, Product2Id from OpportunityLineItem where OpportunityId  =: oppId];
        set<Id> proId = new set<Id>();
        for(OpportunityLineItem opl : opliList){
            system.debug('opl.Product2Id-->'+opl.Product2Id);
            if(string.isNotBlank(opl.Product2Id )){
                proId.add(opl.Product2Id);
            }
        }
        
        List<dataWrapper> dtList = new List<dataWrapper>(); 
        
        
        system.debug('proId'+proId.size());
        if(proId.size() > 0){
            List<Product2> prodList = new List<Product2>();
            prodList = [Select Id,Name from Product2 where Id IN: proId];
            
            Integer Index = 1;
            for(Product2 sob : prodList){
                dataWrapper stb = new dataWrapper();
                stb.Id = sob.Id;
                stb.index = Index++;
                stb.Name = sob.Name;
                stb.openFiles = true;
                stb.closeFiles = false;
                stb.showChildData  = false;
                stb.dataChildFiles = new List<dataChildWrapper>();
                dtList.add(stb);
                
            }
            
        }
        system.debug(dtList.size());
        
        if(dtList.size() > 0)
            return JSON.serialize(dtList);
        else 
            return null;
        
        
    }
    
    @AuraEnabled 
    public static string getFiledDisplay(string prodId){
        List<ContentDocumentLink> cdList = [SELECT ContentDocument.Id, Id,ContentDocument.Title, ContentDocument.FileExtension, LinkedEntityId
                                            FROM ContentDocumentLink where LinkedEntityId=:prodId];
        List<dataChildWrapper> fileList = new List<dataChildWrapper>();
        for(ContentDocumentLink cdl : cdList){
            dataChildWrapper fl = new dataChildWrapper();
            fl.Id = cdl.Id;
            fl.Name = cdl.ContentDocument.Title;
            fl.selectFile = false;
            fileList.add(fl);
        }
        
        if(fileList.size() > 0)
            return JSON.serialize(fileList);
        else 
            return null;
    }
    
    @AuraEnabled 
    public static string getDocumentUrl (string Id){
        
        // List<FileData> files=new List<FileData>();
        system.debug('Id'+Id);
        
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        
        ContentDocumentLink cdl = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE Id = :Id limit 1
        ];
        
        
        ContentVersion  attach = [
            SELECT Id, Title, VersionData,FileExtension, ContentDocumentId, ContentDocument.Title, ContentDocument.CreatedDate
            FROM ContentVersion
            WHERE ContentDocumentId = :cdl.ContentDocumentId
            AND ContentDocument.filetype != 'mp4'
            ORDER BY CreatedDate DESC limit 1];
        
        return attach.ContentDocumentId;
    }
    
    @AuraEnabled
    public static string sendMailToCustomer(string toAdd, string cc, string subject, string body, string fileId){
        system.debug('toAdd===>>'+toAdd);
        system.debug('cc===>>'+cc);
        system.debug('subject===>>'+subject);
        system.debug('body===>>'+body);
        system.debug('fileId===>>'+fileId);
        map<string,string> result = new map<string,string>();
        try{
            List<String> sObj = (List<String>) JSON.deserialize(fileId, List<String>.class);
            
            system.debug('sObj'+sObj);
            
            if(sObj.size() > 0){
                List<ContentDocumentLink> cdlList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE Id IN : sObj];
                set<Id> cDoc_id = new set<Id> ();
                for(ContentDocumentLink cdl: cdlList){
                    cDoc_id.add(cdl.ContentDocumentId);
                }
                
                
                if(cDoc_id.size() > 0){
                    
                    List<ContentVersion> contentVersions = [SELECT Id, Title, VersionData,FileExtension, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :cDoc_id];
                    
                    
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<String> toEmails = toAdd.split(',');
                    system.debug('toEmails'+toEmails);
                    mail.setToAddresses(toEmails );
                    if(string.isNotBlank(cc)){
                            List<String> ccEmails = cc.split(', ');

                        mail.setCcAddresses(ccEmails);
                    }
                    mail.setSubject(subject);
                    mail.setHtmlBody(body);
                    
                    List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
                    
                    for(ContentVersion contentVersion : contentVersions) {
                        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                        attachment.setFileName(contentVersion.Title+'.'+contentVersion.FileExtension);
                        attachment.setBody(contentVersion.VersionData);
                        attachments.add(attachment);
                    }
                    
                    
                    // Attach the files to the email
                    mail.setFileAttachments(attachments);
                    
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
					result.put('Success','success');
                }
                
                
                
            }
        }catch(exception e){
            result.put('error',string.valueOf(e.getLineNumber()) +' '+ e.getMessage()); 
        }
        system.debug('JSON.serialize(result)'+JSON.serialize(result));
        return JSON.serialize(result);
    }
    
    
    
    public static List<dataWrapper> parse(string js){
        return (List<dataWrapper>)system.JSON.deserialize(js,List<dataWrapper>.class);
    }
    
    public with sharing class dataWrapper{
        public string Id;
        public Integer index;
        public string Name;
        public string status;
        public boolean openFiles;
        public boolean showChildData;
        public boolean closeFiles;
        List<dataChildWrapper> dataChildFiles;
    }
    
    public with sharing class dataChildWrapper{
        public string Id;
        public Integer index;
        public string Name;
        public boolean selectFile = false;
    }
    
}