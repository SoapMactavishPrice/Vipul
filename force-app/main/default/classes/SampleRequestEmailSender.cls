public class SampleRequestEmailSender {
    @future(callout=true)
    public static void sendEmailAsync(Id sampleRequestId) {
        System.debug('Entered sendEmailAsync method');
        
        Sample_Request__c request = [SELECT Id, Name, Person__r.Email, Status__c FROM Sample_Request__c WHERE Id = :sampleRequestId];
        System.debug('Sample_Request__c record: ' + request.Id);
        
        List<Sample_In__c> sampleIns = [SELECT Id, Sample_Sent_to_Unit__c, Name, Application__c, Sample_Sent_to_Unit__r.Name, VOL_Product_Name__c, VOL_Product_Name__r.Name, C_I__c,
                                        Sample_Request__c, Sample_Request__r.Name, Sample_Request__r.Request_Date__c, Sample_Request__r.Person__c, Sample_Request__r.Person__r.Name
                                        FROM Sample_In__c WHERE Sample_Request__c = :request.Id];
        
        List<Sample_Out__c> sampleOuts = [SELECT Id, Sample_Sent_to_Unit__c, Name, Application__c, Product_Name__c, Product_Name__r.Name, Colour_Index_Name__c, Quality__c, Quantity__c,
                                          Sample_Request__c, Sample_Request__r.Name, Sample_Request__r.Request_Date__c, Sample_Request__r.Person__c, Sample_Request__r.Person__r.Name,
                                          Sample_Sent_to_Unit__r.Name, Packets__c, Unit_of_Measure__c
                                          FROM Sample_Out__c WHERE Sample_Request__c = :request.Id];
        
        System.debug('Sample_In__c records found: ' + sampleIns.size());
        System.debug('Sample_Out__c records found: ' + sampleOuts.size());
        
        String emailBody = 'Sample Request No: ' + request.Name + '<br/><br/>';
        
        if (!sampleIns.isEmpty()) {
            emailBody += 'Sample In Records:<br/>';
           // emailBody += '---------------------------------<br/>';
            emailBody += 'Below are the product details for your reference:<br/><br/>';
            emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
            emailBody += '<thead><tr style="background-color: #f2f2f2;"><th>S.In No</th><th>Factory</th><th>Request Date</th><th>Product Name</th><th>CI No</th><th>Marketing Person</th><th>Application</th></tr></thead><tbody>';
            
            for (Sample_In__c sampleIn : sampleIns) {
                emailBody += '<tr>';
                emailBody += '<td>' + sampleIn.Name + '</td>';
                emailBody += '<td>' + (sampleIn.Sample_Sent_to_Unit__r.Name != null ? sampleIn.Sample_Sent_to_Unit__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleIn.Sample_Request__r.Request_Date__c != null ? sampleIn.Sample_Request__r.Request_Date__c.format() : '') + '</td>';
                emailBody += '<td>' + (sampleIn.VOL_Product_Name__r.Name != null ? sampleIn.VOL_Product_Name__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleIn.C_I__c != null ? sampleIn.C_I__c : '') + '</td>';
                emailBody += '<td>' + (sampleIn.Sample_Request__r.Person__r.Name != null ? sampleIn.Sample_Request__r.Person__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleIn.Application__c != null ? sampleIn.Application__c : '') + '</td>';
                emailBody += '</tr>';
            }
            
            emailBody += '</tbody></table><br/><br/>';
        }
        
        if (!sampleOuts.isEmpty()) {
            emailBody += 'Sample Out Records:<br/>';
          //  emailBody += '---------------------------------<br/>';
            emailBody += 'Below are the product details for your reference:<br/><br/>';
            emailBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
            emailBody += '<thead><tr style="background-color: #f2f2f2;"><th>S.Out No</th><th>Factory</th><th>Request Date</th><th>Product Name</th><th>CI No</th><th>Marketing Person</th><th>Application</th><th>Quality</th><th>Quantity</th></tr></thead><tbody>';
            
            for (Sample_Out__c sampleOut : sampleOuts) {
                emailBody += '<tr>';
                emailBody += '<td>' + sampleOut.Name + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Sent_to_Unit__r.Name != null ? sampleOut.Sample_Sent_to_Unit__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Request__r.Request_Date__c != null ? sampleOut.Sample_Request__r.Request_Date__c.format() : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Product_Name__r.Name != null ? sampleOut.Product_Name__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Colour_Index_Name__c != null ? sampleOut.Colour_Index_Name__c : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Sample_Request__r.Person__r.Name != null ? sampleOut.Sample_Request__r.Person__r.Name : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Application__c != null ? sampleOut.Application__c : '') + '</td>';
                emailBody += '<td>' + (sampleOut.Quality__c != null ? sampleOut.Quality__c : '') + '</td>';
                emailBody += '<td>' + sampleOut.Quantity__c + (sampleOut.Packets__c != null ? ' x ' + sampleOut.Packets__c : '') + ' ' + sampleOut.Unit_of_Measure__c + '</td>';
                emailBody += '</tr>';
            }
            
            emailBody += '</tbody></table><br/><br/>';
        }
        
        // Collect all unique Sample_Sent_to_Unit__c IDs
        Set<Id> unitIds = new Set<Id>();
        for (Sample_In__c sampleIn : sampleIns) {
            unitIds.add(sampleIn.Sample_Sent_to_Unit__c);
        }
        for (Sample_Out__c sampleOut : sampleOuts) {
            unitIds.add(sampleOut.Sample_Sent_to_Unit__c);
        }
        
        // Query for email addresses of all units
        List<Unit_Master__c> units = [SELECT Email_1__c, Email_2__c FROM Unit_Master__c WHERE Id IN :unitIds];
        
        List<String> toAddresses = new List<String>();
        List<String> ccAddresses = new List<String>();
        
        for (Unit_Master__c unit : units) {
            if (unit.Email_1__c != null) {
                toAddresses.add(unit.Email_1__c);
            }
            if (unit.Email_2__c != null) {
                toAddresses.add(unit.Email_2__c);
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
            email.setWhatId(sampleRequestId);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('Email sent');
            
            // Update the status to 'Proposed'
            //request.Status__c = 'Proposed';
           // update request;

        } else {
            System.debug('No email addresses found for units');
        }
    }
}