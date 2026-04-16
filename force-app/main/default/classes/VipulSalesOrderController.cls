public class VipulSalesOrderController {
    
    public id qid {get;set;}
    public id pid {get;set;}
    public id oid {get;set;}
    public Quote quo {get;set;}
    public List<QuoteLineItem> qlList{get;set;}
    public Proforma_Invoice__c pi {get;set;}
    public List<Proforma_Invoice_Line_Item__c> piList{get;set;}
    public Order so {get;set;}
    public List<OrderItem> soList{get;set;}
    public List<Opportunity> oppList{get;set;}
    public Product2 prod {get;set;}
    public String userName { get; set; }
    public String userTitle { get; set; }
    public String userMobile { get; set; }
    public String currentMonthYear { get; set; }
    public PageReference pdf { get; set; }
    public String pdfURL { get; set; }
    public String pdfName { get; set; }
    public String PiNo { get; set; }
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
    public string no2words {get;set;}
    public string Grand_Total {get;set;}
    public Date PiDate {get;set;}
    public Date BuyersDate {get;set;}
    public Date RevisedDate {get;set;}
    public Date ShipmentDate {get;set;}
    public string ConAddress {get;set;}
    public String DelAddress {get;set;}
    public String amountInWords { get; set; }
    public Boolean isDomestic { get; set; }
    public Boolean isInternational { get; set; }
    public Map<String, String> packingTypeMap {get; set;}
    
    
    public VipulSalesOrderController() {
        pid = ApexPages.currentPage().getparameters().get('id');
        if (pid == null) {
            pid = 'a0GHy00000EDNwVMAX';
        }
        isValid = true;
        system.debug('pid' + pid);
        piList = new List<Proforma_Invoice_Line_Item__c>();
        
        List<Proforma_Invoice__c> piListQuery = [SELECT Id, OwnerId, Name, CurrencyIsoCode, Proforma_Invoice_Number__c, Enquiry_Name__c, Owner.Name, Account_Name__c,
                                                 Account_Name__r.Name, Account_Name__r.Phone, Account_Name__r.Landline_Number_1__c, Revision_Number__c, Notify_Information__c,
                                                 Account_Name__r.Email_ID__c, Account_Name__r.Country__r.Name, Account_Name__r.State__r.Name, Account_Name__r.City__r.Name,
                                                 Account_Name__r.Area__r.Name, Account_Name__r.Pin_Code__r.Name, Account_Name__r.Street__c, Country_Status__c,
                                                 Expiration_Date__c, Syncing__c, Status__c, Discount__c, Tax__c, Shipping_and_Handling__c, Contact_Name__c, Email__c, 
                                                 Contact_Name__r.Name, Contact_Name__r.MobilePhone, Contact_Name__r.Phone, Contact_Name__r.Email, Proforma_Invoice_Type__c,
                                                 Phone__c, Description__c, Quote__c, Subtotal__c, Total_Price__c, Consignee_Address1__c, Delivery_Address1__c,
                                                 Pre_Carriage_by__c, Place_of_Receipt_by_Pre_Carrier__c, Port_of_Loading__c, Vessel_Flight_No__c, Port_of_Discharge__c,
                                                 Final_Destination__c, Country_of_Final_Destination__c, SO_No__c, SO_Date__c, Country_of_Origin__c, Buyer__c, Notify__c,
                                                 Inco_Terms__c, Delivery_Schedule__c, Payment_Terms__c, Buyer_s_Ref__c, Total_Quantity__c, Country_Rating__c,
                                                 Pallet_Packing__c, Nomination_Agent__c, Shipment_Date__c, PreShipment_Inspection__c, PSS__c, QC_sample_in_Shipment__c,
                                                 Buyer_s_Date__c, Company_Bank__r.Name, Revision_Date__c, Shipment_Type__c, Container_Type__c, Goods_Type__c,
                                                 Detention_Free_Period_Required__c, Extended_Period__c, Signed_Copy_of_Sales_Order__c, ECGC_Status__c, Type_of_Pallet__c,
                                                 Vol_Logo_on_Packing__c, Commission_if_Any__c, Commission_Comment__c, Document_to_be_Send__c, Any_Other_Specification__c,
                                                 Customer_s_Bank_Details__c, BL_Instruction__c, BL_Instruction_Comments__c, Contact_Info_for_Logistic_Purpose__c,
                                                 Company_Bank__r.Beneficiary_Name__c, Company_Bank__r.SWIFT_Code__c, Company_Bank__r.Account_Number__c, 
                                                 Company_Bank__r.Correspondent_Swift_Bank_Code__c, Transport_Value__c, GST_Amount__c, TCS_Value__c, Total_Value__c,
                                                 Buyer__r.Name, Notify__r.Name, Grand_Total__c, Country_of_Final_Destination__r.Name, Delivery_Address_Same_As_Consignee__c,
                                                 Consignee_Address1__r.Country__r.Name, Consignee_Address1__r.State__r.Name, Consignee_Address1__r.City__r.Name,
                                                 Consignee_Address1__r.Area__r.Name, Consignee_Address1__r.Pin_Code__r.Name, Consignee_Address1__r.Street__c,
                                                 Delivery_Address1__r.Country__r.Name, Delivery_Address1__r.State__r.Name, Delivery_Address1__r.City__r.Name,
                                                 Delivery_Address1__r.Area__r.Name, Delivery_Address1__r.Pin_Code__r.Name, Delivery_Address1__r.Street__c
                                                 FROM Proforma_Invoice__c WHERE Id = :pid];
        
        if (!piListQuery.isEmpty()) {
            pi = piListQuery[0];
            
            isDomestic = pi.Proforma_Invoice_Type__c == 'Domestic';
            isInternational = pi.Proforma_Invoice_Type__c == 'International';
            
        } else {
            System.debug('No Proforma Invoice found for the given Id');
            return;
        }
        
        if (isInternational) {
            List<String> missingFields = new List<String>();
            //if (pi.Revision_Date__c == null) missingFields.add('Revision Date');
            if (pi.Buyer__c == null) missingFields.add('Buyer');
            //if (pi.Notify__c == null) missingFields.add('Notify');
            if (pi.Signed_Copy_of_Sales_Order__c == null) missingFields.add('Signed Copy of Sales Order');
            if (pi.Account_Name__c == null) missingFields.add('Account Name');
            if (pi.ECGC_Status__c == null) missingFields.add('ECGC Status');
            if (pi.Country_Status__c == null) missingFields.add('Country Status');
            //if (pi.Country_Rating__c == null) missingFields.add('Country Rating');
            if (pi.PSS__c == null) missingFields.add('PSS');
            if (pi.PreShipment_Inspection__c == null) missingFields.add('PreShipment Inspection');
            if (pi.QC_sample_in_Shipment__c == null) missingFields.add('QC sample in Shipment');
            if (pi.Nomination_Agent__c == null) missingFields.add('Nomination Agent');
            if (pi.Port_of_Discharge__c == null) missingFields.add('Port of Discharge');
            if (pi.Country_of_Final_Destination__c == null) missingFields.add('Country of Final Destination');
            if (pi.Shipment_Type__c == null) missingFields.add('Shipment Type');
            if (pi.Container_Type__c == null) missingFields.add('Container Type');
            if (pi.Goods_Type__c == null) missingFields.add('Goods Type');
            if (pi.Detention_Free_Period_Required__c == null) missingFields.add('Detention Free Period Required');
            //if (pi.Extended_Period__c == null) missingFields.add('Extended Period');
            if (pi.Vol_Logo_on_Packing__c == null) missingFields.add('Vol Logo on Packing');
            if (pi.Commission_if_Any__c == null) missingFields.add('Commission if Any');
            if (pi.Commission_Comment__c == null) missingFields.add('Commission Comment');
            if (pi.Document_to_be_Send__c == null) missingFields.add('Document to be Send');
            //if (pi.BL_Instruction__c == null) missingFields.add('BL Instruction');
            //if (pi.BL_Instruction_Comments__c == null) missingFields.add('BL Instruction Comments');
            if (pi.Contact_Info_for_Logistic_Purpose__c == null) missingFields.add('Contact Info for Logistic Purpose');

            if (!missingFields.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                'Missing required international fields: ' + String.join(missingFields, ', ')));
                isValid = false;
                System.debug('Missing required international fields: ' + String.join(missingFields, ', '));
            }
        }
        
        
        if (isDomestic) {
            List<String> missingFields = new List<String>();
            if (pi.Consignee_Address1__c == null) missingFields.add('Consignee Address');
            if (pi.Delivery_Address1__c == null) missingFields.add('Delivery Address');
            if (pi.Account_Name__c == null) missingFields.add('Account Name');
            if (pi.Payment_Terms__c == null) missingFields.add('Payment Terms');
            if (pi.Inco_Terms__c == null) missingFields.add('Inco Terms');
            if (pi.Contact_Name__c == null) missingFields.add('Contact Name');
            if (pi.Company_Bank__c == null) missingFields.add('Company Bank');
            //if (pi.Pallet_Packing__c == null) missingFields.add('Pallet Packing');


            if (!missingFields.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                'Missing required Domestic fields: ' + String.join(missingFields, ', ')));
                isValid = false;
                System.debug('Missing required Domestic fields: ' + String.join(missingFields, ', '));
            }
        }
        
        
        emailId = pi.Contact_Name__r.Email;
        subject = 'Vipul Organics - Proforma Invoice';
        body = 'Dear Sir/Madam, <br/><br/>';
        body += 'Please find attached Proforma Invoice.<br/><br/><br/><br/>';
        body += 'Thanks and regards, <br/>';
        body += UserInfo.getName() + '<br/>';
        
        pdf = Page.VipulSalesOrderPDF;
        pdfURL = '/apex/VipulSalesOrderPDF?id='+pid+'#toolbar=0';
        
        
        piList = [SELECT Id, Name, CurrencyIsoCode, Product__c, Proforma_Invoice_Name__c, Quantity__c, Discount_Percentage__c, 
                  Line_Item_Description__c, List_Price__c, Sales_Price__c, Subtotal__c, Total_Price__c , Product__r.Application__c,
                  Product__r.ProductCode, Product__r.Description, Product__r.Packing_Type__c, Product__r.Unit__c, Packing_Type__c,
                  Product__r.Packing__c, Quality__c, Packing__c, Box_Drum__c, Pallet_Quantity__c, Pallet_No__c, Product__r.HSN_No__c
                  FROM Proforma_Invoice_Line_Item__c WHERE Proforma_Invoice_Name__c = :pi.Id];
        
        initPackingTypeMap();
        Set<Id> soids = new Set<Id>();
        
        /*for(Proforma_Invoice_Line_Item__c test1 : piList){
            // Your logic here
        }*/
        
        
        
        // Retrieve the current user or user associated with the Proforma Invoice
        User currentUser = [SELECT Id, Name, Title, MobilePhone FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        // Assign values to variables
        userName = currentUser.Name;
        userTitle = currentUser.Title;
        userMobile = currentUser.MobilePhone != null ? currentUser.MobilePhone : ''; // Handle null mobile number
        
        
        
        // Get the current month and year
        Datetime now = Datetime.now();
        currentMonthYear = now.format('MMMM yyyy', 'en_US'); 
        
        
        pdfName = pi.Name;
        PiNo = pi.Proforma_Invoice_Number__c;
        formSubmitted = false;
        //isValid = true;
        createNew = true;
        
        PiDate = pi.SO_Date__c;
        BuyersDate = pi.Buyer_s_Date__c;
        ShipmentDate = pi.Shipment_Date__c;
        RevisedDate = pi.Revision_Date__c;
        
        // Convert total amount to words
        CurrencyToWords converter = new CurrencyToWords();
        converter.numberval = pi.Total_Price__c.longValue();
        String totalValueINRWords = converter.getConvertedValue();

        // Check the currency and set the amount in words accordingly
        if (pi.CurrencyIsoCode == 'INR') {
            amountInWords = totalValueINRWords + ' Rupees Only.';
        } else {
            amountInWords = totalValueINRWords + 'USD Only.';
        }
        
        ConAddress = '';
        if (String.isNotBlank(pi.Consignee_Address1__r.Street__c)) {
            ConAddress += pi.Consignee_Address1__r.Street__c;
        }
        if (String.isNotBlank(pi.Consignee_Address1__r.Area__r.Name)) {
            if (!String.isBlank(ConAddress)) {
                ConAddress += ', ';
            }
            ConAddress += pi.Consignee_Address1__r.Area__r.Name;
        }
        if (String.isNotBlank(pi.Consignee_Address1__r.City__r.Name)) {
            if (!String.isBlank(ConAddress)) {
                ConAddress += ', ';
            }
            ConAddress += pi.Consignee_Address1__r.City__r.Name;
        }
        if (String.isNotBlank(pi.Consignee_Address1__r.Pin_Code__r.Name)) {
            if (!String.isBlank(ConAddress)) {
                ConAddress += ', ';
            }
            ConAddress += pi.Consignee_Address1__r.Pin_Code__r.Name;
        }
        if (String.isNotBlank(pi.Consignee_Address1__r.State__r.Name)) {
            if (!String.isBlank(ConAddress)) {
                ConAddress += ', ';
            }
            ConAddress += pi.Consignee_Address1__r.State__r.Name;
        }
        if (String.isNotBlank(pi.Consignee_Address1__r.Country__r.Name)) {
            if (!String.isBlank(ConAddress)) {
                ConAddress += ', ';
            }
            ConAddress += pi.Consignee_Address1__r.Country__r.Name;
        }
        
        
        DelAddress = '';
        if (String.isNotBlank(pi.Delivery_Address1__r.Street__c)) {
            DelAddress += pi.Delivery_Address1__r.Street__c;
        }
        if (String.isNotBlank(pi.Delivery_Address1__r.Area__r.Name)) {
            if (!String.isBlank(DelAddress)) {
                DelAddress += ', ';
            }
            DelAddress += pi.Delivery_Address1__r.Area__r.Name;
        }
        if (String.isNotBlank(pi.Delivery_Address1__r.City__r.Name)) {
            if (!String.isBlank(DelAddress)) {
                DelAddress += ', ';
            }
            DelAddress += pi.Delivery_Address1__r.City__r.Name;
        }
        if (String.isNotBlank(pi.Delivery_Address1__r.Pin_Code__r.Name)) {
            if (!String.isBlank(DelAddress)) {
                DelAddress += ', ';
            }
            DelAddress += pi.Delivery_Address1__r.Pin_Code__r.Name;
        }
        if (String.isNotBlank(pi.Delivery_Address1__r.State__r.Name)) {
            if (!String.isBlank(DelAddress)) {
                DelAddress += ', ';
            }
            DelAddress += pi.Delivery_Address1__r.State__r.Name;
        }
        if (String.isNotBlank(pi.Delivery_Address1__r.Country__r.Name)) {
            if (!String.isBlank(DelAddress)) {
                DelAddress += ', ';
            }
            DelAddress += pi.Delivery_Address1__r.Country__r.Name;
        }

    }
    
    public PageReference save() {
        
        // Check if Salestype is null
        /*if (String.isBlank(Salestype)) {
            // Add an error message to the page
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: Sales type must be selected.'));
            return null; // Prevent further processing and stay on the same page
        }*/
        
        
        String finalString = '%' + pi.Name + '%';
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
        contentVersion.PathOnClient = String.valueOf(pi.Name+ '_' + newVersion + '.pdf');
        contentVersion.Title = String.valueOf(pi.Name + '_' + newVersion + '.pdf');
        contentVersion.isMajorVersion = false;
        if(Test.isRunningTest())
            ContentVersion.versionData = Blob.toPdf('test');
        else
            ContentVersion.versionData = pdf.getContentAsPDF();
        upsert contentVersion;
        
        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: contentVersion.Id];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = pi.Id;
        contentDocumentLink.ShareType = 'V';
        upsert contentDocumentLink;
        
        Pagereference pageRef = new PageReference('/'+pid);
        pageRef.setRedirect(true);
        return pageRef;    
    }
    
    public PageReference saveAndSend() {
        
        /*if (String.isBlank(Salestype)) {
            // Add an error message to the page
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: Sales type must be selected.'));
            return null; // Prevent further processing and stay on the same page
        }*/
        
        
        if(emailId != '' && subject != '') {
            String finalString = '%' + pi.Name + '%';
            List<ContentDocument> contentDocs = [select Id, title from ContentDocument where title like: finalString order by createdDate desc limit 1];
            String version = '0';
            if(contentDocs.size() > 0)
                version = contentDocs[0].title.substringAfterLast('_').subStringBeforelast('.');
            if(!createNew) {
                if(contentDocs.size() > 0)
                    Database.delete(contentDocs, false);
            }
            
            List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
            if(pid!=null)
                cdls = [select id, ContentDocument.LatestPublishedVersionId from ContentDocumentLink where LinkedEntityId =: pid];
            Set<String> LatestPublishedVersionIds = new Set<String>();
            /*  for(ContentDocumentLink cdl: cdls) {
LatestPublishedVersionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
}*/
            formSubmitted = true;
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S';
            Integer newVersion = Integer.valueOf(version) + 1;
            contentVersion.PathOnClient = String.valueOf(pi.Name+ '_' + newVersion + '.pdf');
            contentVersion.Title = String.valueOf(+ pi.Name + '_' + newVersion + '.pdf');
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
            contentDocumentLink.LinkedEntityId = pid;
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
            
            email.setReplyTo(pi.Contact_Name__r.Email);
            if(String.isNotBlank(pi.Contact_Name__r.Email)) {
                email.setBccAddresses(new List<String> {pi.Contact_Name__r.Email});
            }
            email.setSubject(subject);
            email.setHtmlBody(body);
            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            sendEmailSuccess = true;
            sendEmailError = false;
            
            /*Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            //email.setToAddresses(new String[] {ownerEmail});
            email.setToAddresses(new String[] {'ankit@finessedirect.com'});
            email.setSubject(subject);
            email.setHtmlBody(body);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});*/
            
            
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email Id and subject are the mandatory fields, please verify'));
            return null;
        }
        
        Pagereference pageRef = new PageReference('/'+pid);
        pageRef.setRedirect(true);
        return pageRef;
        
    }
    
    public String getPaymentTermsLabel() {
        Map<String, Schema.PicklistEntry> pickVals = new Map<String, Schema.PicklistEntry>();
        
        // Describe the field
        Schema.DescribeFieldResult fieldResult = 
            Proforma_Invoice__c.Payment_Terms__c.getDescribe();
        
        // Build a map of Value → PicklistEntry
        for (Schema.PicklistEntry p : fieldResult.getPicklistValues()) {
            pickVals.put(p.getValue(), p);
        }
        
        // Return the label for the current value
        if (pi != null && pickVals.containsKey(pi.Payment_Terms__c)) {
            return pickVals.get(pi.Payment_Terms__c).getLabel();
        }
        return '';
    }
    
    
    public PageReference cancel() {
        Pagereference pageRef = new PageReference('/'+pid);
        pageRef.setRedirect(true);
        formSubmitted = false;
        return pageRef;
        
    }
    
    public void initPackingTypeMap() {
        packingTypeMap = new Map<String, String>();
        
        Schema.DescribeFieldResult fieldResult =
            Proforma_Invoice_Line_Item__c.Packing_Type__c.getDescribe();
        
        for (Schema.PicklistEntry p : fieldResult.getPicklistValues()) {
            packingTypeMap.put(p.getValue(), p.getLabel());
        }
    }
    
    public String getPackingTypeLabel(String apiValue) {
        return packingTypeMap.containsKey(apiValue)
            ? packingTypeMap.get(apiValue)
            : apiValue;
    }
}