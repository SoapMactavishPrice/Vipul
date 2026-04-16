public class SampleOutEmailSender {
    
    @future(callout=true)
    public static void sendEmailAsync(Id sampleRequestOutId) {
        System.debug('Entered sendEmailAsync method');
        
        Sample_Out_Request__c request = [SELECT Id, Name, Person__r.Email FROM Sample_Out_Request__c WHERE Id = :sampleRequestOutId];
        System.debug('Sample_Out_Request__c record: ' + request.Id);
        
        
        List<Sample_Out__c> sampleOuts = [SELECT Id, Sample_Sent_to_Unit__c, Name, Application__c, Product_Name__c, Product_Name__r.Name, Colour_Index_Name__c, Quality__c, Quantity__c,
                                          Sample_Out_Request__c, Sample_Out_Request__r.Name, Sample_Out_Request__r.Request_Date__c, Sample_Out_Request__r.Person__c, Sample_Out_Request__r.Person__r.Name,
                                              Sample_Sent_to_Unit__r.Name, Packets__c, Unit_of_Measure__c, New_Product__c, New_Product_Name__c, New_Product_CI_No__c, Product_Name__r.CI_no__c
                                          FROM Sample_Out__c WHERE Sample_Out_Request__c = :request.Id];
        
        System.debug('Sample_Out__c records found: ' + sampleOuts.size());
        
        String emailBody = 'Sample Request No: ' + request.Name + '<br/><br/>';
        
                
        if (!sampleOuts.isEmpty()) {
            emailBody += 'Requested Product Records:<br/><br/>';
          //  emailBody += '---------------------------------<br/>';
            emailBody += 'Below are the product details for your reference:<br/><br/>';
            emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
            emailBody += '<thead><tr style="background-color: #f2f2f2;"><th>Requested Product No</th><th>Factory</th><th>Request Date</th><th>Product Name</th><th>CI No</th><th>Marketing Person</th><th>Application</th><th>Quality</th><th>Quantity in Grams</th></tr></thead><tbody>';
            
            for (Sample_Out__c sampleOut : sampleOuts) {
                emailBody += '<tr>';
                emailBody += '<td>' + sampleOut.Name + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Sent_to_Unit__r.Name != null ? sampleOut.Sample_Sent_to_Unit__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Out_Request__r.Request_Date__c != null ? sampleOut.Sample_Out_Request__r.Request_Date__c.format() : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Product_Name__r.Name != null ? sampleOut.Product_Name__r.Name : (sampleOut.New_Product_Name__c != null ? sampleOut.New_Product_Name__c : '')) + '</td>';
                emailBody += '<td>' + (sampleOut.Product_Name__r.CI_no__c != null ? sampleOut.Product_Name__r.CI_no__c : (sampleOut.New_Product_CI_No__c != null ? sampleOut.New_Product_CI_No__c : '')) + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Out_Request__r.Person__r.Name != null ? sampleOut.Sample_Out_Request__r.Person__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Application__c != null ? sampleOut.Application__c : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Quality__c != null ? sampleOut.Quality__c : '') + '</td>';
                emailBody += '<td>' + sampleOut.Quantity__c + (sampleOut.Packets__c != null ? ' x ' + sampleOut.Packets__c : '') + '</td>';
                emailBody += '</tr>';
            }
            
            emailBody += '</tbody></table><br/><br/>';
        }
        
        // Collect all unique Sample_Sent_to_Unit__c IDs
        Set<Id> unitIds = new Set<Id>();
        for (Sample_Out__c sampleOut : sampleOuts) {
            unitIds.add(sampleOut.Sample_Sent_to_Unit__c);
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
            email.setSubject('Sample Request Created');
            email.setHtmlBody(emailBody); // Use setHtmlBody instead of setPlainTextBody
            email.setWhatId(sampleRequestOutId);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('Email sent');
            
        } else {
            System.debug('No email addresses found for units');
        }
    }
    
    @future(callout=true)
    public static void sendHOEmailAsync(Id sampleRequestOutId) {
        Sample_Out_Request__c request = [SELECT Id, Name, Person__r.Email FROM Sample_Out_Request__c WHERE Id = :sampleRequestOutId];
        
        List<Sample_Out__c> sampleOuts = [SELECT Id, Sample_Sent_to_Unit__c, Name, Application__c, Product_Name__c, Product_Name__r.Name, Colour_Index_Name__c, Quality__c, Quantity__c,
                                          Sample_Out_Request__c, Sample_Out_Request__r.Name, Sample_Out_Request__r.Request_Date__c, Sample_Out_Request__r.Person__c, Sample_Out_Request__r.Person__r.Name,
                                              Sample_Sent_to_Unit__r.Name, Packets__c, Unit_of_Measure__c, New_Product__c, New_Product_Name__c, New_Product_CI_No__c, Product_Name__r.CI_no__c,
                                          Sample_Out_Status__c, Email_Sent_to_HO__c
                                          FROM Sample_Out__c
                                          WHERE Sample_Out_Request__c = :sampleRequestOutId AND Sample_Out_Status__c = 'Sample Sent to HO' AND Email_Sent_to_HO__c = false
                                         ];
        
        if (sampleOuts.isEmpty()) {
            System.debug('No Sample_In__c records with status "Sample Sent to HO" found.');
            return;
        }
        
        // Build email body (similar to your existing logic)
        String emailBody = 'Sample Request No: ' + request.Name + '<br/><br/>';
        emailBody += 'Below are the product details sent to HO:<br/><br/>';
        emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
        emailBody += '<thead><tr style="background-color: #f2f2f2;"><th>Requested Product No</th><th>Factory</th><th>Request Date</th><th>Product Name</th><th>CI No</th><th>Marketing Person</th><th>Application</th><th>Quality</th><th>Quantity in Grams</th></tr></thead><tbody>';
            
         for (Sample_Out__c sampleOut : sampleOuts) {
                emailBody += '<tr>';
                emailBody += '<td>' + sampleOut.Name + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Sent_to_Unit__r.Name != null ? sampleOut.Sample_Sent_to_Unit__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Out_Request__r.Request_Date__c != null ? sampleOut.Sample_Out_Request__r.Request_Date__c.format() : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Product_Name__r.Name != null ? sampleOut.Product_Name__r.Name : (sampleOut.New_Product_Name__c != null ? sampleOut.New_Product_Name__c : '')) + '</td>';
                emailBody += '<td>' + (sampleOut.Product_Name__r.CI_no__c != null ? sampleOut.Product_Name__r.CI_no__c : (sampleOut.New_Product_CI_No__c != null ? sampleOut.New_Product_CI_No__c : '')) + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Out_Request__r.Person__r.Name != null ? sampleOut.Sample_Out_Request__r.Person__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Application__c != null ? sampleOut.Application__c : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Quality__c != null ? sampleOut.Quality__c : '') + '</td>';
                emailBody += '<td>' + sampleOut.Quantity__c + (sampleOut.Packets__c != null ? ' x ' + sampleOut.Packets__c : '') + '</td>';
                emailBody += '</tr>';
            }
        
        emailBody += '</tbody></table><br/><br/>';
        
        // Collect all unique Sample_Sent_to_Unit__c IDs
        Set<Id> unitIds = new Set<Id>();
        for (Sample_Out__c sampleOut : sampleOuts) {
            unitIds.add(sampleOut.Sample_Sent_to_Unit__c);
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
        email.setSubject('Sample Request- Sample Sent to HO');
        email.setHtmlBody(emailBody);
        email.setWhatId(sampleRequestOutId);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        
        System.debug('HO Email sent');
        
        // ✅ Mark Sample_In__c records as emailed
        List<Sample_Out__c> samplesToUpdate = new List<Sample_Out__c>();
        for (Sample_Out__c sample : sampleOuts) {
            sample.Email_Sent_to_HO__c = true;
            samplesToUpdate.add(sample);
        }
        if (!samplesToUpdate.isEmpty()) {
            update samplesToUpdate;
        }

    }

}