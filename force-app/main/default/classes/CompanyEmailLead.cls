public class CompanyEmailLead {

    public Id leadId { get; set; }
    public String emailId { get; set; }  // This is where the email will be entered
    public String CC_Addresses { get; set; }
    public String subject { get; set; }
    public String body { get; set; }
    public Boolean isValid { get; set; }
    public Boolean formSubmitted { get; set; }

    public CompanyEmailLead(ApexPages.StandardController controller) {
        this.leadId = controller.getId();
        this.isValid = true;
        
        // Set default subject
        this.subject = 'Vipul Organics Introduction and Product Brochure';

        // Set default body
        this.body = 'Dear Sir/Madam, <br/><br/>' + 
                    'Please find attached Vipul Organics Introduction and Product Brochure.\n\n <br/><br/>';

		body += 'Thanks and regards, <br/>';
        body += UserInfo.getName() + '<br/>';
        
        // Fetch Lead details, including Email
        Lead lead = [SELECT Id, Email, Company
                     FROM Lead
                     WHERE Id = :leadId
                     LIMIT 1];

        // If no email exists for the Lead, show error
        if (String.isEmpty(lead.Email)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                'Lead does not have an email address.'));
            this.isValid = false; // Mark as invalid
            return; // Prevent further processing
        }

        // Default to Lead's Email, but can be changed by user input in Visualforce page
        emailId = lead.Email;
    }

    // Method to handle sending the email
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
            // Fetch Lead details
            Lead lead = [SELECT Id, Email, Company
                         FROM Lead
                         WHERE Id = :leadId LIMIT 1];

            // Validate Lead's email (if it's empty)
            if (String.isEmpty(lead.Email)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Lead does not have an email address.'));
                this.isValid = false; // Mark as invalid
                return null;
            }

            // If user entered a new email, use it
            String recipientEmail = String.isEmpty(emailId) ? lead.Email : emailId;

            // Fetch the required Static Resources (Multiple resources here)
            List<StaticResource> staticResources = [SELECT Id, Body, Name, ContentType 
                                                    FROM StaticResource 
                                                    WHERE Name IN ('CompanyProfileName')];

            if (staticResources.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Static Resources found.'));
                return null;
            }

            // Create and send the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { recipientEmail });

            // Set CC addresses (if any)
            if (!String.isEmpty(CC_Addresses)) {
                email.setCcAddresses(CC_Addresses.split(','));
            }

            email.setSubject(subject);
            email.setHtmlBody(body); // Ensure the body supports HTML content
            email.setUseSignature(true);

            // Attach Multiple Static Resource files
            List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
            for (StaticResource staticResource : staticResources) {
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(staticResource.Name + '.docx'); // Adjust extension if needed

                // Properly decode and set the body (ensure binary content is handled correctly)
                Blob fileBody = staticResource.Body;
                if (fileBody != null) {
                    efa.setBody(fileBody); // Assign the decoded binary content
                }

                // Set the correct content type, e.g., 'application/pdf'
                efa.setContentType('application/pdf');  // Adjust as needed for the file type

                fileAttachments.add(efa);
            }

            // Attach the files to email
            email.setFileAttachments(fileAttachments);

            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Email sent successfully with attachments.'));

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()));
        }
        
        // Redirect back to the Lead page
        return new PageReference('/' + leadId);
    }

    // Cancel method, redirects back to the Lead page
    public PageReference cancel() {
        return new PageReference('/' + leadId);
    }
}