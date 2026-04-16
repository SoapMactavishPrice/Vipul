public class SampleInEmailSender {
    
     @future(callout=true)
    public static void sendEmailAsync(Id sampleRequestInId) {
        System.debug('Entered sendEmailAsync method');
        
        Sample_In_Request__c request = [SELECT Id, Name, Person__r.Email FROM Sample_In_Request__c WHERE Id = :sampleRequestInId];
        System.debug('Sample_In_Request__c record: ' + request.Id);
        
        List<Sample_In__c> sampleIns = [SELECT Id, Sample_Sent_to_Unit__c, Name, Application__c, Sample_Sent_to_Unit__r.Name, VOL_Product_Name__c, VOL_Product_Name__r.Name, C_I__c,
                                        Sample_In_Request__c, Sample_In_Request__r.Name, Sample_In_Request__r.Person__c, Sample_In_Request__r.Person__r.Name, Customer_s_Product_Name__c,
                                        Customer_Reference_No__c, S_In_Ref_No__c, Quantity__c
                                        FROM Sample_In__c WHERE Sample_In_Request__c = :request.Id];
        
                
        String emailBody = 'Sample In No: ' + request.Name + '<br/><br/>';
        
        if (!sampleIns.isEmpty()) {
            emailBody += 'Sample In Products Records:<br/><br/>';
           // emailBody += '---------------------------------<br/>';
            emailBody += 'Below are the product details for your reference:<br/><br/>';
            emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
            emailBody += '<thead><tr style="background-color: #f2f2f2;"><th>S.In No</th><th>Factory</th><th>Product Name</th><th>CI No</th><th>Customer Ref No.</th><th>VOL In Ref No.</th><th>Qty in Grams</th><th>Marketing Person</th><th>Application</th></tr></thead><tbody>';
            
            for (Sample_In__c sampleIn : sampleIns) {
                emailBody += '<tr>';
                emailBody += '<td>' + sampleIn.Name + '</td>';
                emailBody += '<td>' + (sampleIn.Sample_Sent_to_Unit__r.Name != null ? sampleIn.Sample_Sent_to_Unit__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleIn.Customer_s_Product_Name__c != null ? sampleIn.Customer_s_Product_Name__c : '') + '</td>';
                emailBody += '<td>' + (sampleIn.C_I__c != null ? sampleIn.C_I__c : '') + '</td>';
                emailBody += '<td>' + (sampleIn.Customer_Reference_No__c != null ? sampleIn.Customer_Reference_No__c : '') + '</td>';
                emailBody += '<td>' + (sampleIn.S_In_Ref_No__c != null ? sampleIn.S_In_Ref_No__c : '') + '</td>';
                emailBody += '<td>' + (sampleIn.Quantity__c != null ? String.valueOf(sampleIn.Quantity__c) : '') + '</td>';
                emailBody += '<td>' + (sampleIn.Sample_In_Request__r.Person__r.Name != null ? sampleIn.Sample_In_Request__r.Person__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleIn.Application__c != null ? sampleIn.Application__c : '') + '</td>';
                emailBody += '</tr>';
            }
            
            emailBody += '</tbody></table><br/><br/>';
        }
        
        
        // Collect all unique Sample_Sent_to_Unit__c IDs
        Set<Id> unitIds = new Set<Id>();
        for (Sample_In__c sampleIn : sampleIns) {
            unitIds.add(sampleIn.Sample_Sent_to_Unit__c);
        }
        
        // Query for email addresses of all units
        List<Unit_Master__c> units = [SELECT Email_1__c, Email_2__c, Email_3__c, Email_4__c, Email_5__c, Email_6__c FROM Unit_Master__c WHERE Id IN :unitIds];
        
        List<String> toAddresses = new List<String>();
        List<String> ccAddresses = new List<String>();
        
        for (Unit_Master__c unit : units) {
            if (unit.Email_1__c != null) {
                toAddresses.add(unit.Email_1__c);
            }
            if (unit.Email_2__c != null) {
                toAddresses.add(unit.Email_2__c);
            }
            if (unit.Email_3__c != null) {
                toAddresses.add(unit.Email_3__c);
            }
            if (unit.Email_4__c != null) {
                toAddresses.add(unit.Email_4__c);
            }
            if (unit.Email_5__c != null) {
                toAddresses.add(unit.Email_5__c);
            }
            if (unit.Email_6__c != null) {
                toAddresses.add(unit.Email_6__c);
            }
        }
        
        // Add the request person's email to CC
        if (request.Person__r.Email != null) {
            ccAddresses.add(request.Person__r.Email);
        }
        
        if (!toAddresses.isEmpty()) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toAddresses);
            email.setCcAddresses(ccAddresses);
            email.setSubject('Sample In Created');
            email.setHtmlBody(emailBody); // Use setHtmlBody instead of setPlainTextBody
            email.setWhatId(sampleRequestInId);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('Email sent');
            

        } else {
            System.debug('No email addresses found for units');
        }
    }
    
    @future(callout=true)
    public static void sendHOEmailAsync(Id sampleRequestInId) {
        Sample_In_Request__c request = [SELECT Id, Name, Person__r.Email FROM Sample_In_Request__c WHERE Id = :sampleRequestInId];
        
        List<Sample_In__c> sampleIns = [
            SELECT Id, Name, Sample_In_Status__c, Sample_Sent_to_Unit__r.Name, Customer_s_Product_Name__c, C_I__c, Email_Sent_to_HO__c,
            Customer_Reference_No__c, S_In_Ref_No__c, Quantity__c, Sample_In_Request__r.Person__r.Name, Application__c
            FROM Sample_In__c
            WHERE Sample_In_Request__c = :sampleRequestInId AND Sample_In_Status__c = 'Sample Sent to HO' AND Email_Sent_to_HO__c = false
        ];
        
        if (sampleIns.isEmpty()) {
            System.debug('No Sample_In__c records with status "Sample Sent to HO" found.');
            return;
        }
        
        // Build email body (similar to your existing logic)
        String emailBody = 'Sample In No: ' + request.Name + '<br/><br/>';
        emailBody += 'Below are the product details sent to HO:<br/><br/>';
        emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        emailBody += '<thead><tr style="background-color: #f2f2f2;"><th>S.In No</th><th>Factory</th><th>Product Name</th><th>CI No</th><th>Customer Ref No.</th><th>VOL In Ref No.</th><th>Qty in Grams</th><th>Marketing Person</th><th>Application</th></tr></thead><tbody>';
        
        for (Sample_In__c sampleIn : sampleIns) {
            emailBody += '<tr>';
            emailBody += '<td>' + sampleIn.Name + '</td>';
            emailBody += '<td>' + (sampleIn.Sample_Sent_to_Unit__r.Name != null ? sampleIn.Sample_Sent_to_Unit__r.Name : '') + '</td>';
            emailBody += '<td>' + (sampleIn.Customer_s_Product_Name__c != null ? sampleIn.Customer_s_Product_Name__c : '') + '</td>';
            emailBody += '<td>' + (sampleIn.C_I__c != null ? sampleIn.C_I__c : '') + '</td>';
            emailBody += '<td>' + (sampleIn.Customer_Reference_No__c != null ? sampleIn.Customer_Reference_No__c : '') + '</td>';
            emailBody += '<td>' + (sampleIn.S_In_Ref_No__c != null ? sampleIn.S_In_Ref_No__c : '') + '</td>';
            emailBody += '<td>' + (sampleIn.Quantity__c != null ? String.valueOf(sampleIn.Quantity__c) : '') + '</td>';
            emailBody += '<td>' + (sampleIn.Sample_In_Request__r.Person__r.Name != null ? sampleIn.Sample_In_Request__r.Person__r.Name : '') + '</td>';
            emailBody += '<td>' + (sampleIn.Application__c != null ? sampleIn.Application__c : '') + '</td>';
            emailBody += '</tr>';
        }
        
        emailBody += '</tbody></table><br/><br/>';
        
        // Collect all unique Sample_Sent_to_Unit__c IDs
        Set<Id> unitIds = new Set<Id>();
        for (Sample_In__c sampleIn : sampleIns) {
            unitIds.add(sampleIn.Sample_Sent_to_Unit__c);
        }
        
        // Query for email addresses of all units
        List<Unit_Master__c> units = [SELECT Email_1__c, Email_2__c, Email_3__c, Email_4__c, Email_5__c, Email_6__c FROM Unit_Master__c WHERE Id IN :unitIds];
        
        List<String> toAddresses = new List<String>();
        List<String> ccAddresses = new List<String>();
        
        for (Unit_Master__c unit : units) {
            if (unit.Email_1__c != null) {
                toAddresses.add(unit.Email_1__c);
            }
            if (unit.Email_2__c != null) {
                toAddresses.add(unit.Email_2__c);
            }
            if (unit.Email_3__c != null) {
                toAddresses.add(unit.Email_3__c);
            }
            if (unit.Email_4__c != null) {
                toAddresses.add(unit.Email_4__c);
            }
            if (unit.Email_5__c != null) {
                toAddresses.add(unit.Email_5__c);
            }
            if (unit.Email_6__c != null) {
                toAddresses.add(unit.Email_6__c);
            }
        }
        
        // Add the request person's email to CC
        if (request.Person__r.Email != null) {
            ccAddresses.add(request.Person__r.Email);
        }
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(ccAddresses);
        email.setCcAddresses(toAddresses);
        email.setSubject('Sample In- Sample Sent to HO');
        email.setHtmlBody(emailBody);
        email.setWhatId(sampleRequestInId);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        
        System.debug('HO Email sent');
        
        // ✅ Mark Sample_In__c records as emailed
        List<Sample_In__c> samplesToUpdate = new List<Sample_In__c>();
        for (Sample_In__c sample : sampleIns) {
            sample.Email_Sent_to_HO__c = true;
            samplesToUpdate.add(sample);
        }
        if (!samplesToUpdate.isEmpty()) {
            update samplesToUpdate;
        }

    }


}