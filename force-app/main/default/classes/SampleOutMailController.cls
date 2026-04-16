public class SampleOutMailController {
    
    public id sid {get;set;}
    public Sample_Out_Request__c sm {get;set;}
    public Boolean isValid { get; set; }
    public List<Sample_Out__c> outList{get;set;}
    public List<wrapclass> listwrap{get; set;}
    public String emailId { get; set; }
    public Boolean createNew { get; set; }
    public String subject { get; set; }
    public String body { get; set; }
    public String CC_Addresses { get; set; }
    public Boolean sendEmailSuccess { get; set; }
    public Boolean sendEmailError { get; set; }
    public Boolean formSubmitted { get; set; }
    
    public SampleOutMailController(){
        
        sid = ApexPages.currentPage().getparameters().get('id');
        if (sid == null) {
            sid = 'a0e71000001Zbk5AAC';
        }
        isValid = true;
        
        system.debug('sid'+sid);
        outList = new List<Sample_Out__c>();
        listwrap  = new List<wrapclass>();
        
        sm = [SELECT Id, Name, Person__r.Email, Request_Date__c, Received_Date__c,
              Country__c, Company_Name__c, OwnerId, Enquiry_Name__c, Company_Name__r.Email_ID__c
              FROM Sample_Out_Request__c WHERE Id = :sid];
        
        
        outList = [SELECT Id, Sample_Sent_to_Unit__c, Name, Application__c, Product_Name__c, Product_Name__r.Name, Colour_Index_Name__c, Quality__c, Quantity__c,
                                          Sample_Out_Request__c, Sample_Out_Request__r.Name, Sample_Out_Request__r.Request_Date__c, Sample_Out_Request__r.Person__c, Sample_Out_Request__r.Person__r.Name,
                                          Sample_Sent_to_Unit__r.Name, Packets__c, Unit_of_Measure__c, Reference_Number__c, Tracking_Number__c, New_Product_Name__c
                                          FROM Sample_Out__c WHERE Sample_Out_Request__c = :sm.Id AND Sample_Out_Status__c = 'Sample Sent to Customer'];
        
        emailId = sm.Company_Name__r.Email_ID__c;
        
        
        subject = 'Vipul Organics - Sample Request';
        body = 'Dear Sir/Madam, <br/><br/>';
        body += 'We are sending here with following samples for your approval.<br/><br/>';
        
       // body += 'Below are the product details for your reference:<br/><br/>';
        body += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        body += '<thead><tr style="background-color: #f2f2f2;"><th>PRODUCTS</th><th>REF NO</th><th>QUANTITY IN GRAMS</th></tr></thead><tbody>';
        
        
        // Loop through the Quote Line Items and add them to the table
        for (Sample_Out__c item : outList) {
            body += '<tr>';
            body += '<td>' + (item.Product_Name__r.Name != null ? item.Product_Name__r.Name : (item.New_Product_Name__c != null ? item.New_Product_Name__c : '')) + '</td>';
            body += '<td>' + (item.Reference_Number__c != null ? item.Reference_Number__c : '') + '</td>';
            body += '<td>' + (item.Quantity__c != null ? item.Quantity__c.toString() : '') + '</td>';
            body += '</tr>';
        }
        
        
        body += '</tbody></table><br/><br/>';
        
        body += 'Please confirm the same upon receipt and advise us your approval upon due evaluation of this sample.<br/><br/>';
        
        body += 'We await your positive reply.<br/>';
        
		String trackingNumber = (outList.isEmpty() || outList[0].Tracking_Number__c == null) ? '' : outList[0].Tracking_Number__c;
		body += 'FEDEX : ' + trackingNumber + '<br/><br/>';  
        
        body += 'Thanks and regards, <br/>';
        body += UserInfo.getName() + '<br/>';

        formSubmitted = false;
        //isValid = true;
        createNew = true;
        
    }
    
    
    
    public PageReference saveAndSend() {
            
        if(emailId != '' && subject != '') {
            String finalString = '%' + sm.Name + '%';
            
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
            
            
            email.setReplyTo(sm.Company_Name__r.Email_ID__c);
            if(String.isNotBlank(sm.Company_Name__r.Email_ID__c)) {
                email.setBccAddresses(new List<String> {sm.Company_Name__r.Email_ID__c});
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
        public Sample_Out__c sm {get;set;}
        public list<OrderItem>tList{get;set;}
        public wrapclass(Sample_Out__c ben,list<OrderItem>data){
        this.sm=ben;
        this.tList=data;
        }
       
    } 

}