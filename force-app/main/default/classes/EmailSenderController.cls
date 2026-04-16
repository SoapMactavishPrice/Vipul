public class EmailSenderController {
    
    // Fetch Product Interested records related to the Lead
    @AuraEnabled(cacheable=true)
    public static List<Product_Interested__c> getProducts(Id leadId) {
        return [SELECT Id, Name, Vipul_Product_Name__c, Product_Code__c, /*Product_Description__c, */Price__c, Quantity__c, Lead__c
                FROM Product_Interested__c 
                WHERE Lead__c = :leadId];
    }

    // Send Email with optional attachments
    @AuraEnabled
    public static String sendEmail(Id leadId, String subject, String body, String toAddress, List<Id> attachmentIds) {
        try {
            // Create Email Message
            EmailMessage emailMessage = new EmailMessage();
            emailMessage.Subject = subject;
            emailMessage.HtmlBody = body;
            emailMessage.ToAddress = toAddress; // This will support comma-separated emails
            emailMessage.Status = '3'; // Sent
            emailMessage.Incoming = false;

            // Set ParentId to Lead ID (not Case ID)
            //emailMessage.ParentId = leadId;
            
            // Insert EmailMessage record
            insert emailMessage;

            // Attach files if there are any
            if (attachmentIds != null && !attachmentIds.isEmpty()) {
                List<ContentDocumentLink> contentLinks = new List<ContentDocumentLink>();
                for (Id attachmentId : attachmentIds) {
                    contentLinks.add(new ContentDocumentLink(
                        ContentDocumentId = attachmentId,
                        LinkedEntityId = emailMessage.Id,
                        ShareType = 'V'
                    ));
                }
                insert contentLinks;
            }

            return 'Email Sent Successfully';
        } catch (DmlException e) {
            throw new AuraHandledException('Error inserting EmailMessage: ' + e.getMessage());
        }
    }
}