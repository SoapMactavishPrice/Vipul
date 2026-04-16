public class CaseEscalationHandler {
    public static void sendEscalationEmails(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Case c : newCases) {
            Case oldCase = oldCaseMap.get(c.Id);

            if (!oldCase.IsEscalated && c.IsEscalated) {
                // Check if the owner is a User (not a Queue)
                if (String.valueOf(c.OwnerId).startsWith('005')) {
                    // Safe to query User
                    User owner = [
                        SELECT Id, Name, Email, Manager.Email 
                        FROM User 
                        WHERE Id = :c.OwnerId 
                        LIMIT 1
                    ];

                    if (owner.Email != null) {
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                        String caseLink = 'https://login.salesforce.com/' + c.Id;

                        String subject = '🚨 Escalation Alert: Case ' + c.CaseNumber + ' - "' + c.Subject + '"';
                        String body = 'Hi ' + owner.Name + ',\n\n' +
                            'This is to notify you that the following case has been escalated:\n\n' +
                            'Case Number: ' + c.CaseNumber + '\n' +
                            'Subject: ' + c.Subject + '\n' +
                            'Priority: ' + c.Priority + '\n' +
                            'Current Owner: ' + owner.Name + '\n' +
                            'Escalated On: ' + String.valueOf(System.now()) + '\n\n' +
                            'Please log in to Salesforce to review the case and take appropriate action.\n\n' +
                            'View Case in Salesforce: ' + caseLink;

                        email.setToAddresses(new String[] { owner.Email });

                        if (owner.Manager != null && owner.Manager.Email != null) {
                            email.setCcAddresses(new String[] { owner.Manager.Email });
                        }
						email.setWhatId(c.Id);
                        email.setSubject(subject);
                        email.setPlainTextBody(body);

                        emailsToSend.add(email);
                    }
                }
                // Else: Owner is a Queue — skip
            }
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }
    
    public static void sendEmailToContactAndPlant(Case caseRecord) {
        Unit_Master__c unit = [SELECT Email_1__c, Email_2__c, Email_3__c, Email_4__c, Email_5__c, Email_6__c 
                               FROM Unit_Master__c 
                               WHERE Id = :caseRecord.Plant__c 
                               LIMIT 1];

        List<String> ccEmails = new List<String>();
        if (unit.Email_1__c != null) ccEmails.add(unit.Email_1__c);
        if (unit.Email_2__c != null) ccEmails.add(unit.Email_2__c);
        if (unit.Email_3__c != null) ccEmails.add(unit.Email_3__c);
        if (unit.Email_4__c != null) ccEmails.add(unit.Email_4__c);
        if (unit.Email_5__c != null) ccEmails.add(unit.Email_5__c);
        if (unit.Email_6__c != null) ccEmails.add(unit.Email_6__c);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{caseRecord.ContactEmail});
        mail.setCcAddresses(ccEmails);
        mail.setWhatId(caseRecord.Id); // Associate email with Case
        mail.setSubject('New Case Created - ' + caseRecord.CaseNumber + ' - "' + caseRecord.Subject + '"');
        mail.setPlainTextBody('Dear Customer,\n\nA new case has been created with Case Number: ' + caseRecord.CaseNumber +
                              '.\n\nWe will get back to you shortly.\n\nThank you,\nSupport Team');

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    
    public static void sendStatusChangeEmails(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        List<Messaging.SingleEmailMessage> statusEmails = new List<Messaging.SingleEmailMessage>();
        
        for (Case c : newCases) {
            Case oldCase = oldCaseMap.get(c.Id);
            
            Boolean statusChanged = c.Status != oldCase.Status;
            Boolean isTargetStatus = c.Status == 'Complaint Lodge' || c.Status == 'In Progress' || c.Status == 'Complaint Resolution';
            
            if (statusChanged && isTargetStatus && c.Plant__c != null && c.ContactEmail != null) {
                Unit_Master__c unit = [SELECT Email_1__c, Email_2__c, Email_3__c, Email_4__c, Email_5__c, Email_6__c 
                                       FROM Unit_Master__c 
                                       WHERE Id = :c.Plant__c 
                                       LIMIT 1];
                
                List<String> ccEmails = new List<String>();
                if (unit.Email_1__c != null) ccEmails.add(unit.Email_1__c);
                if (unit.Email_2__c != null) ccEmails.add(unit.Email_2__c);
                if (unit.Email_3__c != null) ccEmails.add(unit.Email_3__c);
                if (unit.Email_4__c != null) ccEmails.add(unit.Email_4__c);
                if (unit.Email_5__c != null) ccEmails.add(unit.Email_5__c);
                if (unit.Email_6__c != null) ccEmails.add(unit.Email_6__c);
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{c.ContactEmail});
                mail.setCcAddresses(ccEmails);
                mail.setWhatId(c.Id);
                mail.setSubject('Case Status Updated - ' + c.CaseNumber + ' - "' + c.Subject + '"');
                
                String body;
                if (c.Status == 'Complaint Resolution') {
                    body = 'Dear Customer,\n\nYour case (' + c.CaseNumber + ') has been resolved.\n\n' +
                        'Responsible Person: ' + (c.Responsible_Person__c != null ? c.Responsible_Person__c : 'N/A') + '\n' +
                        'Comments: ' + (c.Comments != null ? c.Comments : 'No comments provided.') + '\n\n' +
                        'Thank you,\nSupport Team';
                } else {
                    body = 'Dear Customer,\n\nThe status of your case (' + c.CaseNumber + ') has been updated to "' + 
                        c.Status + '".\n\nWe are actively working on it.\n\nThank you,\nSupport Team';
                }
                
                mail.setPlainTextBody(body);
                statusEmails.add(mail);
            }
        }
        
        if (!statusEmails.isEmpty()) {
            Messaging.sendEmail(statusEmails);
        }
    }
    
    public static void processResponsiblePersonChanges(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        Set<Id> responsiblePersonIdsToNotify = new Set<Id>();
        Map<Id, List<Id>> caseToNotifyIds = new Map<Id, List<Id>>();

        for (Case c : newCases) {
            List<Id> notifyIds = new List<Id>();
            Case oldCase = oldCaseMap != null ? oldCaseMap.get(c.Id) : null;

            // Case Responsible Person
            if (c.Case_Responsible_Person__c != null &&
                (oldCase == null || c.Case_Responsible_Person__c != oldCase.Case_Responsible_Person__c)) {
                notifyIds.add(c.Case_Responsible_Person__c);
                responsiblePersonIdsToNotify.add(c.Case_Responsible_Person__c);
            }

            // Corrective Responsible Person
            if (c.Corrective_Responsible_Person__c != null &&
                (oldCase == null || c.Corrective_Responsible_Person__c != oldCase.Corrective_Responsible_Person__c)) {
                notifyIds.add(c.Corrective_Responsible_Person__c);
                responsiblePersonIdsToNotify.add(c.Corrective_Responsible_Person__c);
            }

            // Preventive Responsible Person
            if (c.Preventive_Responsible_Person__c != null &&
                (oldCase == null || c.Preventive_Responsible_Person__c != oldCase.Preventive_Responsible_Person__c)) {
                notifyIds.add(c.Preventive_Responsible_Person__c);
                responsiblePersonIdsToNotify.add(c.Preventive_Responsible_Person__c);
            }

            if (!notifyIds.isEmpty()) {
                caseToNotifyIds.put(c.Id, notifyIds);
            }
        }

        if (responsiblePersonIdsToNotify.isEmpty()) return;

        Map<Id, Responsible_Person__c> rpMap = new Map<Id, Responsible_Person__c>(
            [SELECT Id, Email__c FROM Responsible_Person__c WHERE Id IN :responsiblePersonIdsToNotify]
        );
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Case c : newCases) {
            List<Id> notifyIds = caseToNotifyIds.get(c.Id);
            if (notifyIds == null) continue;
            
            for (Id rpId : notifyIds) {
                Responsible_Person__c rp = rpMap.get(rpId);
                if (rp != null && rp.Email__c != null) {
                    String body = '';
                    String subject = 'New Case Assignment: ' + c.CaseNumber;
                    
                    if (c.Case_Responsible_Person__c == rpId) {
                        body = 'You have been assigned to a case.\n\n' +
                            'Case Number: ' + c.CaseNumber + '\n' +
                            'Subject: ' + c.Subject + '\n' +
                            'Details: ' + c.Description;
                    } else if (c.Corrective_Responsible_Person__c == rpId) {
                        body = 'You have been assigned to a case.\n\n' +
                            'Case Number: ' + c.CaseNumber + '\n' +
                            'Subject: ' + c.Subject + '\n\n' +
                            'Please provide the **Corrective Action** for this case.';
                    } else if (c.Preventive_Responsible_Person__c == rpId) {
                        body = 'You have been assigned to a case.\n\n' +
                            'Case Number: ' + c.CaseNumber + '\n' +
                            'Subject: ' + c.Subject + '\n\n' +
                            'Please provide the **Preventive Action** for this case.';
                    }
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[] { rp.Email__c });
                    mail.setSubject(subject);
                    mail.setWhatId(c.Id);
                    mail.setPlainTextBody(body);
                    emails.add(mail);
                }
            }
        }


        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

}