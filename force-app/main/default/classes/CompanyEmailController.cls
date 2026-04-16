public class CompanyEmailController {

    public Id oppId { get; set; }
    public String emailId { get; set; }
    public String CC_Addresses { get; set; }
    public String subject { get; set; }
    public String body { get; set; }
    public Boolean isValid { get; set; }
    public Boolean formSubmitted { get; set; }

    public CompanyEmailController(ApexPages.StandardController controller) {
        this.oppId = controller.getId();
        this.isValid = true;
        
        // Set default subject
        this.subject = 'Vipul Organics Introduction and Product Brochure';

        // Set default body
        this.body = 'Dear Sir/Madam, <br/><br/>' + 
                    'Please find attached Vipul Organics Introduction and Product Brochure.\n\n';
        
        // Fetch Opportunity details, including primary Contact email
        Opportunity opp = [SELECT Id, Contact__c, Contact__r.Email, StageName, AccountId
                           FROM Opportunity 
                           WHERE Id = :oppId 
                           LIMIT 1];

        // Validate that Sales_Type__c and Contact__c are not empty
        if (opp.Contact__c == null || opp.Contact__r.Email == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                'Primary Contact Email is missing for this Opportunity.'));
            this.isValid = false; // Mark as invalid
            return; // Prevent further processing
        }

        // Set primary email (Opportunity's Contact__r.Email)
        emailId = opp.Contact__r.Email;

        // Fetch all related Contacts and prepare CC emails
        List<Contact> relatedContacts = [SELECT Email 
                                         FROM Contact 
                                         WHERE AccountId = :opp.AccountId 
                                         AND Email != null];
        
        List<String> ccList = new List<String>();
        for (Contact contact : relatedContacts) {
            if (contact.Email != opp.Contact__r.Email) {
                ccList.add(contact.Email);
            }
        }
        CC_Addresses = String.join(ccList, ', ');
    }

    public PageReference sendEmail() {
        // Reset the validity flag for new attempts
        this.isValid = true;

        // Validate mandatory fields before proceeding
        if (String.isEmpty(emailId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Recipient email address is mandatory.'));
            this.isValid = false; // Mark as invalid
            return null; // Stop further processing
        }

        if (String.isEmpty(subject)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Subject is mandatory.'));
            this.isValid = false; // Mark as invalid
            return null; // Stop further processing
        }

        try {
            // Fetch Opportunity details
            Opportunity opp = [SELECT Id, Contact__r.Email, AccountId, StageName
                               FROM Opportunity 
                               WHERE Id = :oppId LIMIT 1];

            // Validate primary email
            if (opp.Contact__c == null || opp.Contact__r.Email == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The related contact is not selected or does not have an email.'));
                this.isValid = false; // Mark as invalid
                return null;
            }

            // Fetch multiple Static Resources for attachments
            List<StaticResource> staticResources = [SELECT Id, Body, Name, ContentType 
                                                    FROM StaticResource 
                                                    WHERE Name ='CompanyProfileName'];

            if (staticResources.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Static Resources found.'));
                return null;
            }

            // Create and send the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { opp.Contact__r.Email });
            
            // Set CC addresses
            if (!String.isEmpty(CC_Addresses)) {
                email.setCcAddresses(CC_Addresses.split(','));
            }

            email.setSubject(subject);
            email.setHtmlBody(body); // Ensure the body supports HTML content
            email.setUseSignature(true);

            // Create a list to hold multiple file attachments
            List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();

            // Attach each Static Resource
            for (StaticResource staticResource : staticResources) {
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(staticResource.Name + '.docx'); // Ensure the correct extension
                efa.setBody(staticResource.Body); // Use the Blob body directly
                efa.setContentType('application/pdf'); // Ensure content type is set to PDF
                fileAttachments.add(efa); // Add each attachment to the list
            }

            // Attach the files to email
            email.setFileAttachments(fileAttachments);
            email.setSaveAsActivity(true);

            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Email sent successfully with attachments.'));

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()));
        }
        
        // Redirect back to the Opportunity page
        return new PageReference('/' + oppId);
    }

    public PageReference cancel() {
        // Redirect back to the Opportunity page on cancel
        return new PageReference('/' + oppId);
    }
}