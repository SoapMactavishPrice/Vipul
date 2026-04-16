public class SampleInOutMailController {
    
    public id sid {get;set;}
    public Sample_In_Request__c sin {get;set;}
    public Boolean isValid { get; set; }
    public List<Sample_In__c> inList{get;set;}
    public List<wrapclass> listwrap{get; set;}
    public String emailId { get; set; }
    public Boolean createNew { get; set; }
    public String subject { get; set; }
    public String body { get; set; }
    public String CC_Addresses { get; set; }
    public Boolean sendEmailSuccess { get; set; }
    public Boolean sendEmailError { get; set; }
    public Boolean formSubmitted { get; set; }
    
    public SampleInOutMailController(){
        
        sid = ApexPages.currentPage().getparameters().get('id');
        if (sid == null) {
            sid = 'a0e71000001Zbk5AAC';
        }
        isValid = true;
        
        system.debug('sid'+sid);
        inList = new List<Sample_In__c>();
        listwrap  = new List<wrapclass>();
        
        sin = [SELECT Id, Name, Person__r.Email, Received_Date__c,
               Country__c, Company_Name__c, OwnerId, Enquiry_Name__c, Company_Name__r.Email_ID__c
               FROM Sample_In_Request__c WHERE Id = :sid];
        
        inList = [
            SELECT Id, Sample_Sent_to_Unit__c, VOL_Product_Name__c, VOL_Product_Name__r.Name,
            Courier_Tracking_No__c, Sample_Out_Ref_No__c, Sample_In_Request__c,
            Sample_In_Request__r.Name, Sample_Sent_to_Unit__r.Name,
            Sample_In_Request__r.Person__c, Sample_In_Request__r.Person__r.Name,
            Quantity__c, Customer_s_Product_Name__c, Customer_Reference_No__c,
            Sample_In_Status__c
            FROM Sample_In__c
            WHERE Sample_In_Request__c = :sin.Id
            AND Sample_In_Status__c = 'Sample Sent to Customer'
        ];
        
        emailId = sin.Company_Name__r.Email_ID__c;
        
        
        subject = 'Vipul Organics - Sample Request';
        body = 'Dear Sir/Madam, <br/><br/>';
        body += 'We are sending here with following samples for your approval.<br/><br/>';
        
        // body += 'Below are the product details for your reference:<br/><br/>';
        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>CUSTOMER PRODUCT</th><th>CUSTOMER REF NO</th><th>VOL PRODUCTS</th><th>REF NO</th><th>QUANTITY IN GRAMS</th></tr></thead><tbody>';
        
        
        // Loop through the Quote Line Items and add them to the table
        for (Sample_In__c item : inList) {
            body += '<tr>';
            body += '<td>' + (item.Customer_s_Product_Name__c != null ? item.Customer_s_Product_Name__c : '') + '</td>';
            body += '<td>' + (item.Customer_Reference_No__c != null ? item.Customer_Reference_No__c : '') + '</td>';
            body += '<td>' + (item.VOL_Product_Name__r.Name != null ? item.VOL_Product_Name__r.Name : '') + '</td>';
            body += '<td>' + (item.Sample_Out_Ref_No__c != null ? item.Sample_Out_Ref_No__c : '') + '</td>';
            body += '<td>' + (item.Quantity__c != null ? item.Quantity__c.toString() : '') + '</td>';
            body += '</tr>';
        }
        
        
        body += '</tbody></table><br/><br/>';
        
        body += 'Please confirm the same upon receipt and advise us your approval upon due evaluation of this sample.<br/><br/>';
        
        body += 'We await your positive reply.<br/>';
        
		String trackingNumber = (inList.isEmpty() || inList[0].Courier_Tracking_No__c == null) ? '' : inList[0].Sample_Out_Ref_No__c;
		body += 'FEDEX : ' + trackingNumber + '<br/><br/>';  
        
        body += 'Thanks and regards, <br/>';
        body += UserInfo.getName() + '<br/>';

        formSubmitted = false;
        //isValid = true;
        createNew = true;
        
    }
    
    
    
    public PageReference saveAndSend() {
            
        if(emailId != '' && subject != '') {
            String finalString = '%' + sin.Name + '%';
            
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
            
                List<String> LatestPublishedVersionIdList = new List<String>();
                email.setEntityAttachments(LatestPublishedVersionIdList);
            
            
            email.setReplyTo(sin.Company_Name__r.Email_ID__c);
            if(String.isNotBlank(sin.Company_Name__r.Email_ID__c)) {
                email.setBccAddresses(new List<String> {sin.Company_Name__r.Email_ID__c});
            }
            email.setSubject(subject);
            email.setHtmlBody(body);
           // email.setSaveAsActivity(true);
            
            // Use setWhatId for custom objects
            email.setWhatId(sid);

            
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            sendEmailSuccess = true;
            sendEmailError = false;
            
          //  quo.Status = 'In Review';
           // update quo;
            
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email Id and subject are the mandatory fields, please verify'));
            return null;
        }
        
        Pagereference pageRef = new PageReference('/'+sid);
        pageRef.setRedirect(true);
        return pageRef;
        
    }
    public PageReference cancel() {
        Pagereference pageRef = new PageReference('/'+sid);
        pageRef.setRedirect(true);
        formSubmitted = false;
        return pageRef;
        
    }
    
    
    
    public class wrapclass{
        public Sample_In__c sin {get;set;}
        public list<OrderItem>tList{get;set;}
        public wrapclass(Sample_In__c ben,list<OrderItem>data){
        this.sin=ben;
        this.tList=data;
        }
       
    } 

}