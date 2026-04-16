public class QuotationPDFController {
    
    public id qid {get;set;}
    public Quote quo {get;set;}
    public List<OrderItem> ActualQuoteLine{get;set;}
    public List<QuoteLineItem> qlList{get;set;}
    public List<Opportunity> oppList{get;set;}
    public Product2 prod {get;set;}
    public List<wrapclass> listwrap{get; set;}
    public Date expDate {get;set;}
    public Date valDate {get;set;}
    public String userName { get; set; }
    public String userTitle { get; set; }
    public String userMobile { get; set; }
    public String currentMonthYear { get; set; }
    public PageReference pdf { get; set; }
    public String pdfURL { get; set; }
    public String pdfName { get; set; }
    public String QuoNo { get; set; }
    public Boolean formSubmitted { get; set; }
    public Boolean isValid { get; set; }
    public Boolean createNew { get; set; }
    public String subject { get; set; }
    public String body { get; set; }
    public String Salestype { get; set; }
    public String emailId { get; set; }
    public String CC_Addresses { get; set; }
    public Boolean sendEmailSuccess { get; set; }
    public Boolean sendEmailError { get; set; }
    public Boolean isDomestic { get; set; }
    public Boolean isInternational { get; set; }
    public string ConAddress {get;set;}
    public String DelAddress {get;set;}
    public Map<String,String> packingTypeMap {get;set;}
    
    public QuotationPDFController(){
        
        qid = ApexPages.currentPage().getparameters().get('id');
        if (qid == null) {
            qid = '0Q0Hy0000011iRNKAY';
        }
        isValid = true;
        
        system.debug('qid'+qid);
        qlList = new List<QuoteLineItem>();
        listwrap  = new List<wrapclass>();
            
        quo = [SELECT Id, OwnerId, IsDeleted, Name, CurrencyIsoCode, OpportunityId, Pricebook2Id, ContactId, QuoteNumber, IsSyncing, ShippingHandling, 
               Tax, Status, ExpirationDate, Description, Subtotal, TotalPrice, LineItemCount, QuoteToName, AdditionalName, Email, Phone, Fax, 
               ContractId, AccountId, Discount, GrandTotal, CanCreateQuoteLineItems, Consignee_Address1__c, Revision_Number__c, Delivery_Address1__c,
               Account.Name, Consignee_Address1__r.State__r.Name, Consignee_Address1__r.Country__r.Name, Customer_Code__c, Country_of_Origin__c, Port_of_Loading__c,
               Port_of_Destination__c, Mode_of_Shipment__c, Inco_Terms__c, Payment_Terms__c, Validity__c, Lead_Time__c, Contact.Name,Contact.Email,
               Transport_Value__c, Transporter_Name__c, Domestic__c, Quote_Type__c, Grand_Total__c, RecordTypeId, RecordType.Name,
               Total_Value__c, GST_Amount__c, TCS_Value__c, Consignee_Address1__r.Street__c, Consignee_Address1__r.City__r.Name, Consignee_Address1__r.Area__r.Name,
               Consignee_Address1__r.Pin_Code__r.Name, Delivery_Address_Same_As_Consignee__c, Delivery_Address1__r.Street__c, Delivery_Address1__r.City__r.Name, 
               Delivery_Address1__r.Area__r.Name, Delivery_Address1__r.State__r.Name, Delivery_Address1__r.Country__r.Name, Delivery_Address1__r.Pin_Code__r.Name
               FROM Quote WHERE id = :qid];
        
        
        StaticResource sr = [SELECT Id,Body,Name,SystemModStamp FROM StaticResource  WHERE Name = 'VipulLogo' LIMIT 1];
        
        qlList = [SELECT Id, IsDeleted, LineNumber, CurrencyIsoCode, QuoteId, PricebookEntryId, OpportunityLineItemId, Quantity, UnitPrice, 
                  Discount, Description, ServiceDate, Product2Id, SortOrder, ListPrice, Subtotal, TotalPrice, Packing_Type__c, Product2.Name,
                  Product2.CI_no__c, Product2.Unit__c, Product2.Packing__c, Quality__c, Packing__c, Total_Price__c, Sales_Price_with_Inco_Terms__c
                  FROM QuoteLineItem Where QuoteId =: quo.id];
        
        packingTypeMap = new Map<String,String>();

for(Schema.PicklistEntry p : QuoteLineItem.Packing_Type__c.getDescribe().getPicklistValues()){
    packingTypeMap.put(p.getValue(), p.getLabel());
}
        
        // Check if the opportunity record type is Domestic
        //Opportunity opp = [SELECT Id, RecordType.Name FROM Opportunity WHERE Id = :quo.OpportunityId];
        
        system.debug('quo.RecordType.Name---->'+quo.RecordType.Name);
        
        isDomestic = (quo.RecordType.Name == 'Domestic');
        isInternational = (quo.RecordType.Name == 'International');
        
        expDate = quo.ExpirationDate;
        valDate = quo.Validity__c;
        emailId = quo.Contact.Email;
        
        
        subject = 'Vipul Organics - Quote PDF';
        body = 'Dear Sir/Madam, <br/><br/>';
        body += 'Please find attached Quote PDF and Below are the product details for your reference:<br/><br/>';
        
       // body += 'Below are the product details for your reference:<br/><br/>';
        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>Product Name</th><th>CI No</th><th>Packaging</th><th>Quality</th><th>Quantity</th><th>Price</th><th>Value</th></tr></thead><tbody>';
        
        
        // Loop through the Quote Line Items and add them to the table
        for (QuoteLineItem item : qlList) {
            body += '<tr>';
            body += '<td>' + (item.Description != null ? item.Description : '') + '</td>';
            body += '<td>' + (item.Product2.CI_no__c != null ? item.Product2.CI_no__c : '') + '</td>';
            body += '<td>' + (item.Packing__c != null ? item.Packing__c : '') + '</td>';
            body += '<td>' + (item.Quality__c != null ? item.Quality__c : '') + '</td>';
            body += '<td>' + item.Quantity + '</td>';
            body += '<td>' + item.Sales_Price_with_Inco_Terms__c + '</td>';
            body += '<td>' + item.Total_Price__c + '</td>';
            body += '</tr>';
        }
        
        
        body += '</tbody></table><br/><br/>';
        
        body += 'Thanks and regards, <br/>';
        body += UserInfo.getName() + '<br/>';
        
        pdf = Page.QuotePDF;
        pdfURL = '/apex/QuotePDF?id='+qid+'#toolbar=0';
        
        
        
        pdfName = quo.Name;
        QuoNo = quo.QuoteNumber;
        formSubmitted = false;
        //isValid = true;
        createNew = true;
        
        User currentUser = [SELECT Id, Name, Title, MobilePhone FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        ConAddress = '';
        if (String.isNotBlank(quo.Consignee_Address1__r.Street__c)) {
            ConAddress += quo.Consignee_Address1__r.Street__c;
        }
        if (String.isNotBlank(quo.Consignee_Address1__r.Area__r.Name)) {
            if (!String.isBlank(ConAddress)) {
                ConAddress += ', ';
            }
            ConAddress += quo.Consignee_Address1__r.Area__r.Name;
        }
        if (String.isNotBlank(quo.Consignee_Address1__r.City__r.Name)) {
            if (!String.isBlank(ConAddress)) {
                ConAddress += ', ';
            }
            ConAddress += quo.Consignee_Address1__r.City__r.Name;
        }
        if (String.isNotBlank(quo.Consignee_Address1__r.Pin_Code__r.Name)) {
            if (!String.isBlank(ConAddress)) {
                ConAddress += ', ';
            }
            ConAddress += quo.Consignee_Address1__r.Pin_Code__r.Name;
        }
        if (String.isNotBlank(quo.Consignee_Address1__r.State__r.Name)) {
            if (!String.isBlank(ConAddress)) {
                ConAddress += ', ';
            }
            ConAddress += quo.Consignee_Address1__r.State__r.Name;
        }
        if (String.isNotBlank(quo.Consignee_Address1__r.Country__r.Name)) {
            if (!String.isBlank(ConAddress)) {
                ConAddress += ', ';
            }
            ConAddress += quo.Consignee_Address1__r.Country__r.Name;
        }
        
        
        DelAddress = '';
            if (String.isNotBlank(quo.Delivery_Address1__r.Street__c)) {
                DelAddress += quo.Delivery_Address1__r.Street__c;
            }
            if (String.isNotBlank(quo.Delivery_Address1__r.Area__r.Name)) {
                if (!String.isBlank(DelAddress)) {
                    DelAddress += ', ';
                }
                DelAddress += quo.Delivery_Address1__r.Area__r.Name;
            }
            if (String.isNotBlank(quo.Delivery_Address1__r.City__r.Name)) {
                if (!String.isBlank(DelAddress)) {
                    DelAddress += ', ';
                }
                DelAddress += quo.Delivery_Address1__r.City__r.Name;
            }
            if (String.isNotBlank(quo.Delivery_Address1__r.Pin_Code__r.Name)) {
                if (!String.isBlank(DelAddress)) {
                    DelAddress += ', ';
                }
                DelAddress += quo.Delivery_Address1__r.Pin_Code__r.Name;
            }
            if (String.isNotBlank(quo.Delivery_Address1__r.State__r.Name)) {
                if (!String.isBlank(DelAddress)) {
                    DelAddress += ', ';
                }
                DelAddress += quo.Delivery_Address1__r.State__r.Name;
            }
            if (String.isNotBlank(quo.Delivery_Address1__r.Country__r.Name)) {
                if (!String.isBlank(DelAddress)) {
                    DelAddress += ', ';
                }
                DelAddress += quo.Delivery_Address1__r.Country__r.Name;
            }
        
    }
    
    public PageReference save() {
                
        String finalString = '%' + quo.Name + '%';
        List<ContentDocument > contentDocs = [select Id, title from ContentDocument where title like: finalString order by createdDate desc limit 1];
        String version = '0';
        if(contentDocs.size() > 0)
            version = contentDocs[0].title.substringAfterLast('_').subStringBeforelast('.');
        if(!createNew) {
            if(contentDocs.size() > 0)
                Database.delete(contentDocs, false);
        }
        formSubmitted = true;
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S';
        Integer newVersion = Integer.valueOf(version) + 1;
        contentVersion.PathOnClient = String.valueOf(quo.Name+ '_' + newVersion + '.pdf');
        contentVersion.Title = String.valueOf(quo.Name + '_' + newVersion + '.pdf');
        contentVersion.isMajorVersion = false;
        if(Test.isRunningTest())
            ContentVersion.versionData = Blob.toPdf('test');
        else
            ContentVersion.versionData = pdf.getContentAsPDF();
        upsert contentVersion;
        
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: contentVersion.Id];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = quo.Id;
        contentDocumentLink.ShareType = 'V';
        upsert contentDocumentLink;
        
        Pagereference pageRef = new PageReference('/'+qid);
        pageRef.setRedirect(true);
        return pageRef;    
    }
    
    public PageReference saveAndSend() {
            
        if(emailId != '' && subject != '') {
            String finalString = '%' + quo.Name + '%';
            List<ContentDocument> contentDocs = [select Id, title from ContentDocument where title like: finalString order by createdDate desc limit 1];
            String version = '0';
            if(contentDocs.size() > 0)
                version = contentDocs[0].title.substringAfterLast('_').subStringBeforelast('.');
            if(!createNew) {
                if(contentDocs.size() > 0)
                    Database.delete(contentDocs, false);
            }
            
            List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
            if(qid!=null)
                cdls = [select id, ContentDocument.LatestPublishedVersionId from ContentDocumentLink where LinkedEntityId =: qid];
            Set<String> LatestPublishedVersionIds = new Set<String>();
            formSubmitted = true;
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S';
            Integer newVersion = Integer.valueOf(version) + 1;
            contentVersion.PathOnClient = String.valueOf(quo.Name+ '_' + newVersion + '.pdf');
            contentVersion.Title = String.valueOf(+ quo.Name + '_' + newVersion + '.pdf');
            contentVersion.isMajorVersion = false;
            if(Test.isRunningTest())
                ContentVersion.versionData = Blob.toPdf('test');
            else
                ContentVersion.versionData = pdf.getContentAsPDF();
            upsert contentVersion;
            
            contentVersion = [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, Title, versionData
                              FROM ContentVersion WHERE Id =: contentVersion.Id];
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = qid;
            contentDocumentLink.ShareType = 'V';
            upsert contentDocumentLink;
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            System.debug(emailId);
            email.setToAddresses(new String[] {emailId});
            if(String.isNotBlank(CC_Addresses)){
                CC_Addresses = CC_Addresses.replaceAll('[;,:]', ',');
                Set<String> CCEmails = new Set<String>();
                for(String str : CC_Addresses.split(',')) {
                    if(String.isNotBlank(str))
                        CCEmails.add(str);
                }
                
                email.setCcAddresses(new List<String>(CCEmails));
                System.debug(CC_Addresses);
            }
            
            LatestPublishedVersionIds.add(contentVersion.ContentDocument.LatestPublishedVersionId);
            
            if(LatestPublishedVersionIds.size() > 0) {
                List<String> LatestPublishedVersionIdList = new List<String>();
                LatestPublishedVersionIdList.addAll(LatestPublishedVersionIds);
                email.setEntityAttachments(LatestPublishedVersionIdList);
            }
            
            email.setReplyTo(quo.Contact.Email);
            if(String.isNotBlank(quo.Contact.Email)) {
                email.setBccAddresses(new List<String> {quo.Contact.Email});
            }
            email.setSubject(subject);
            email.setHtmlBody(body);
           // email.setSaveAsActivity(true);
            
            // Use setWhatId for custom objects
            email.setWhatId(qid);

            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            sendEmailSuccess = true;
            sendEmailError = false;
            
            /*// Create a task to log the email activity
            Task task = new Task();
            task.Subject = 'Email: ' + subject;
            task.Status = 'Completed';
            task.Priority = 'Normal';
            task.WhatId = quo.Id;
            task.Description = 'Email sent to: ' + emailId + '\n\n' + body;
            insert task;*/
            
            // Update the status of the Quote to 'In Review'
            quo.Status = 'In Review';
            update quo;
            
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email Id and subject are the mandatory fields, please verify'));
            return null;
        }
        
        Pagereference pageRef = new PageReference('/'+qid);
        pageRef.setRedirect(true);
        return pageRef;
        
    }
    public PageReference cancel() {
        Pagereference pageRef = new PageReference('/'+qid);
        pageRef.setRedirect(true);
        formSubmitted = false;
        return pageRef;
        
    }
    
    
    public class wrapclass{
        public QuoteLineItem quo {get;set;}
        public list<OrderItem>tList{get;set;}
        public wrapclass(QuoteLineItem ben,list<OrderItem>data){
        this.quo=ben;
        this.tList=data;
        }
       
    } 
    
    public String getPaymentTermsLabel() {
        if(quo.Payment_Terms__c == null) return '';
        
        for (Schema.PicklistEntry p : Quote.Payment_Terms__c.getDescribe().getPicklistValues()) {
            if (p.getValue() == quo.Payment_Terms__c) {
                return p.getLabel();
            }
        }
        return quo.Payment_Terms__c;
    }
    
    public String getPackingTypeLabel(String value){
        if(value == null) return '';
        
        for(Schema.PicklistEntry p : QuoteLineItem.Packing_Type__c.getDescribe().getPicklistValues()){
            if(p.getValue() == value){
                return p.getLabel();
            }
        }
        return value;
    }

}