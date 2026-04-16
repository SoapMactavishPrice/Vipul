public class LeadTriggerHandler {
    
    public static void updateLeadAddresses(List<Lead> newLeads) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> areaIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        // Collect all relevant IDs from the leads being processed
        for (Lead lead : newLeads) {
            if (lead.Pin_Code__c != null) {
                postalCodeIds.add(lead.Pin_Code__c);
            }
            if (lead.Area__c != null) {
                areaIds.add(lead.Area__c);
            }
            if (lead.City__c != null) {
                cityIds.add(lead.City__c);
            }
            if (lead.State__c != null) {
                stateIds.add(lead.State__c);
            }
        }
        
        // Query the related records
        Map<Id, Pin_Code__c> postalCodeMap = new Map<Id, Pin_Code__c>(
            [SELECT Id, Area__c, Area__r.City__c, Area__r.City__r.State__c, Area__r.City__r.State__r.Country__c FROM Pin_Code__c WHERE Id IN :postalCodeIds]
        );
        Map<Id, Area__c> areaMap = new Map<Id, Area__c>(
            [SELECT Id, City__c, City__r.State__c, City__r.State__r.Country__c FROM Area__c WHERE Id IN :areaIds]
        );
        Map<Id, City__c> cityMap = new Map<Id, City__c>(
            [SELECT Id, State__c, State__r.Country__c FROM City__c WHERE Id IN :cityIds]
        );
        Map<Id, State__c> stateMap = new Map<Id, State__c>(
            [SELECT Id, Country__c FROM State__c WHERE Id IN :stateIds]
        );
        
        // Update the lead fields based on the selected values
        for (Lead lead : newLeads) {
            if (lead.Pin_Code__c != null && postalCodeMap.containsKey(lead.Pin_Code__c)) {
                Pin_Code__c postalCode = postalCodeMap.get(lead.Pin_Code__c);
                lead.Area__c = postalCode.Area__c;
                lead.City__c = postalCode.Area__r.City__c;
                lead.State__c = postalCode.Area__r.City__r.State__c;
                lead.Country__c = postalCode.Area__r.City__r.State__r.Country__c;
            } else if (lead.Area__c != null && areaMap.containsKey(lead.Area__c)) {
                Area__c area = areaMap.get(lead.Area__c);
                lead.City__c = area.City__c;
                lead.State__c = area.City__r.State__c;
                lead.Country__c = area.City__r.State__r.Country__c;
            } else if (lead.City__c != null && cityMap.containsKey(lead.City__c)) {
                City__c city = cityMap.get(lead.City__c);
                lead.State__c = city.State__c;
                lead.Country__c = city.State__r.Country__c;
            } else if (lead.State__c != null && stateMap.containsKey(lead.State__c)) {
                State__c state = stateMap.get(lead.State__c);
                lead.Country__c = state.Country__c;
            }
        }
    }
    
    
    
    public static void handleLeadConversion(Map<Id, Lead> newLeadMap, Map<Id, Lead> oldLeadMap) {
        Set<Id> convertedLeadIds = new Set<Id>();
        Map<Id, Id> leadToAccountMap = new Map<Id, Id>();
        
        // Collect the IDs of converted leads and map them to their accounts
        for (Id leadId : newLeadMap.keySet()) {
            Lead newLead = newLeadMap.get(leadId);
            Lead oldLead = oldLeadMap.get(leadId);
            
            if (newLead.IsConverted && !oldLead.IsConverted) {
                convertedLeadIds.add(leadId);
                leadToAccountMap.put(leadId, newLead.ConvertedAccountId);
            }
        }
        
        if (convertedLeadIds.isEmpty()) {
            return;
        }
        
        // Query the Contact Information related to the converted Leads
        List<Contact_Information__c> contactInfos = [SELECT Name, Email__c, Mobile__c, Designation__c, Department__c, Lead__c, First_Name__c, CurrencyIsoCode  
                                                     FROM Contact_Information__c 
                                                     WHERE Lead__c IN :convertedLeadIds];
        
        List<Contact> contactsToInsert = new List<Contact>();
        
        for (Contact_Information__c contactInfo : contactInfos) {
            // Create a new Contact record
            Contact newContact = new Contact();
            newContact.FirstName = contactInfo.First_Name__c;
            newContact.LastName = contactInfo.Name;
            newContact.Email = contactInfo.Email__c;
            newContact.MobilePhone = contactInfo.Mobile__c;
            newContact.Job_Title_Designation__c = contactInfo.Designation__c;
            newContact.Department = contactInfo.Department__c;
            newContact.LeadSource = 'Converted Lead';
            newContact.CurrencyIsoCode = contactInfo.CurrencyIsoCode;
            
            // Associate the contact with the appropriate account
            newContact.AccountId = leadToAccountMap.get(contactInfo.Lead__c);
            
            // Add the new Contact to the list
            contactsToInsert.add(newContact);
        }
        
        // Insert all new Contact records
        if (!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
        }
    }
    
    public static void handleLeadConversion(List<Lead> leads) {
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, Id> leadToOwnerMap = new Map<Id, Id>();
        Map<Id, Id> leadToCountryMap = new Map<Id, Id>();
        Map<Id, String> leadToTypeMap = new Map<Id, String>();
        Map<Id, String> leadToDescriptionMap = new Map<Id, String>();
        Map<Id, Id> leadToContactMap = new Map<Id, Id>();
        Map<Id, String> leadToContactEmailMap = new Map<Id, String>();
        Map<Id, String> leadToContactMobileMap = new Map<Id, String>();
        Map<Id, String> leadToContactNameMap = new Map<Id, String>();
        Map<Id, String> leadToIncoTermsMap = new Map<Id, String>();
        
        List<Lead> queriedLeads = [SELECT Id, IsConverted, ConvertedOpportunityId, ConvertedAccountId, OwnerId, Country__c, Lead_Type__c, Description, 
                                   ConvertedContactId, Email, MobilePhone, Name, Inco_Terms__c, FirstName, LastName, Job_Title_Designation__c
                                   FROM Lead 
                                   WHERE Id IN :leads];
        
        for (Lead lead : queriedLeads) {
            if (lead.IsConverted && lead.ConvertedOpportunityId != null) {
                opportunityIds.add(lead.ConvertedOpportunityId);
                leadToOwnerMap.put(lead.ConvertedOpportunityId, lead.OwnerId);
                leadToCountryMap.put(lead.ConvertedOpportunityId, lead.Country__c);
                leadToTypeMap.put(lead.ConvertedOpportunityId, lead.Lead_Type__c);
                leadToDescriptionMap.put(lead.ConvertedOpportunityId, lead.Description);
                leadToContactMap.put(lead.ConvertedOpportunityId, lead.ConvertedContactId);
                leadToContactEmailMap.put(lead.ConvertedOpportunityId, lead.Email);
                leadToContactMobileMap.put(lead.ConvertedOpportunityId, lead.MobilePhone);
                leadToContactNameMap.put(lead.ConvertedOpportunityId, lead.LastName);
                leadToIncoTermsMap.put(lead.ConvertedOpportunityId, lead.Inco_Terms__c);
            }
        }
        
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        List<Account> accountsToUpdate = new List<Account>();
        
        if (!opportunityIds.isEmpty()) {
            List<Opportunity> opportunities = [SELECT Id, OwnerId, Who_will_attend__c, Type, Enquiry_Type__c, Customer_Type__c, Country__c, RecordTypeId, AccountId  
                                               FROM Opportunity 
                                               WHERE Id IN :opportunityIds];
            
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, User_Division__c 
                                                       FROM User 
                                                       WHERE Id IN :leadToOwnerMap.values()]);
            
            Map<String, Id> opportunityRecordTypeMap = new Map<String, Id>();
            for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Opportunity']) {
                opportunityRecordTypeMap.put(rt.DeveloperName, rt.Id);
            }
            
            Map<String, Id> accountRecordTypeMap = new Map<String, Id>();
            for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Account']) {
                accountRecordTypeMap.put(rt.DeveloperName, rt.Id);
            }
            
            for (Opportunity opp : opportunities) {
                opp.Who_will_attend__c = leadToOwnerMap.get(opp.Id);
                opp.Customer_Type__c = 'New';
                opp.Country__c = leadToCountryMap.get(opp.Id);
                opp.Inco_Terms__c = leadToIncoTermsMap.get(opp.Id);
                
                String leadType = leadToTypeMap.get(opp.Id);
                if (leadType == 'Domestic' || leadType == 'Both') {
                    opp.RecordTypeId = opportunityRecordTypeMap.get('Domestic');
                } else if (leadType == 'International') {
                    opp.RecordTypeId = opportunityRecordTypeMap.get('International');
                }
                
                opportunitiesToUpdate.add(opp);
                
                if (opp.AccountId != null) {
                    Account acc = new Account(
                        Id = opp.AccountId, 
                        Description = leadToDescriptionMap.get(opp.Id),
                        Contact__c = leadToContactMap.get(opp.Id),
                        Contact_s_Email__c = leadToContactEmailMap.get(opp.Id),
                        Contact_s_Mobile__c = leadToContactMobileMap.get(opp.Id),
                        Contact_Name__c = leadToContactNameMap.get(opp.Id)
                    );
                    
                    if (leadType == 'Domestic' || leadType == 'Both') {
                        acc.RecordTypeId = accountRecordTypeMap.get('Domestic');
                    } else if (leadType == 'International') {
                        acc.RecordTypeId = accountRecordTypeMap.get('International');
                    }
                    
                    accountsToUpdate.add(acc);
                }
            }
        }
        
        // Handle leads converted without Opportunity
        Map<String, Id> accountRecordTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Account']) {
            accountRecordTypeMap.put(rt.DeveloperName, rt.Id);
        }
        
        for (Lead lead : queriedLeads) {
            if (lead.IsConverted && lead.ConvertedOpportunityId == null && lead.ConvertedAccountId != null) {
                Account acc = new Account(
                    Id = lead.ConvertedAccountId,
                    Description = lead.Description,
                    Contact__c = lead.ConvertedContactId,
                    Contact_s_Email__c = lead.Email,
                    Contact_s_Mobile__c = lead.MobilePhone,
                    Contact_First_Name__c = lead.FirstName,
                    Designation__c = lead.Job_Title_Designation__c,
                    Contact_Name__c = lead.LastName
                );
                
                if (lead.Lead_Type__c == 'Domestic' || lead.Lead_Type__c == 'Both') {
                    acc.RecordTypeId = accountRecordTypeMap.get('Domestic');
                } else if (lead.Lead_Type__c == 'International') {
                    acc.RecordTypeId = accountRecordTypeMap.get('International');
                }
                
                accountsToUpdate.add(acc);
            }
        }
        
        try {
            if (!opportunitiesToUpdate.isEmpty()) {
                update opportunitiesToUpdate;
            }
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
        } catch (DmlException e) {
            System.debug('Error updating records: ' + e.getMessage());
        }
    }
    
    
    public static void updateContactFieldOnOpportunity(List<Lead> leads) {
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        
        for (Lead lead : leads) {
            if (lead.IsConverted && lead.ConvertedOpportunityId != null && lead.ConvertedContactId != null) {
                Opportunity opp = [SELECT Id, Contact__c FROM Opportunity WHERE Id = :lead.ConvertedOpportunityId];
                opp.Contact__c = lead.ConvertedContactId;
                opportunitiesToUpdate.add(opp);
            }
        }
        
        if (!opportunitiesToUpdate.isEmpty()) {
            update opportunitiesToUpdate;
        }
    }
    
    public static void setLeadTypeBasedOnUserDivision(List<Lead> leads) {
        // Get the current user's division and profile
        User currentUser = [SELECT User_Division__c, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        String userDivision = currentUser.User_Division__c;
        String userProfile = currentUser.Profile.Name;
        
        // Check if the user is not a System Administrator
        if (userProfile != 'System Administrator') {
            // Iterate through the leads and set the Lead_Type__c based on the user's division
            for (Lead lead : leads) {
                if (userDivision == 'Domestic') {
                    lead.Lead_Type__c = 'Domestic';
                } else if (userDivision == 'International') {
                    lead.Lead_Type__c = 'International';
                }
            }
        }
    }
  
    public static void UpdateSampleRequestFields(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        // Collect requests and child outs to update
        List<Sample_Out_Request__c> requestsToUpdate = new List<Sample_Out_Request__c>();
        List<Sample_Out__c> sampleOutsToUpdate = new List<Sample_Out__c>();
        
        // 1) Gather the Lead Ids that just converted
        Set<Id> justConvertedLeadIds = new Set<Id>();
        for (Lead ld : newLeads) {
            Lead oldLead = oldLeadMap.get(ld.Id);
            if (oldLead != null && !oldLead.IsConverted && ld.IsConverted) {
                justConvertedLeadIds.add(ld.Id);
            }
        }
        
        if (justConvertedLeadIds.isEmpty()) {
            return;
        }
        
        // 2) Map Lead Id → (ConvertedAccountId, ConvertedOpportunityId)
        Map<Id, Id> leadToAccount = new Map<Id, Id>();
        Map<Id, Id> leadToOpp = new Map<Id, Id>();
        for (Lead ld : newLeads) {
            if (justConvertedLeadIds.contains(ld.Id)) {
                leadToAccount.put(ld.Id, ld.ConvertedAccountId);
                leadToOpp.put(ld.Id, ld.ConvertedOpportunityId);
            }
        }
        
        // 3) Query related Sample_Out_Request__c for all converted leads IN ONE GO
        List<Sample_Out_Request__c> relatedRequests = [
            SELECT Id, Lead__c, Company_Name__c, Enquiry_Name__c
            FROM Sample_Out_Request__c
            WHERE Lead__c IN :justConvertedLeadIds
        ];
        
        // 4) Update each request's fields
        Set<Id> requestIds = new Set<Id>();
        for (Sample_Out_Request__c req : relatedRequests) {
            // Align request fields with converted lead values
            req.Company_Name__c = leadToAccount.get(req.Lead__c);
            req.Enquiry_Name__c = leadToOpp.get(req.Lead__c);
            requestsToUpdate.add(req);
            requestIds.add(req.Id);
        }
        
        // 5) Query all child Sample_Out__c records for these requests
        if (!requestIds.isEmpty()) {
            // Pull parent Company_Name__c into memory to copy to children
            Map<Id, Id> requestIdToCompany = new Map<Id, Id>();
            for (Sample_Out_Request__c req : relatedRequests) {
                requestIdToCompany.put(req.Id, req.Company_Name__c);
            }
            
            // Query children
            List<Sample_Out__c> childSampleOuts = [
                SELECT Id, Sample_Out_Request__c, Company_Name__c
                FROM Sample_Out__c
                WHERE Sample_Out_Request__c IN :requestIds
            ];
            
            // 6) Update child Company_Name__c to match parent request
            for (Sample_Out__c outRec : childSampleOuts) {
                Id parentCompany = requestIdToCompany.get(outRec.Sample_Out_Request__c);
                // Only set if different or not already set to prevent unnecessary DML
                if (parentCompany != null && outRec.Company_Name__c != parentCompany) {
                    outRec.Company_Name__c = parentCompany;
                    sampleOutsToUpdate.add(outRec);
                }
            }
        }
        
        // 7) DML — keep to minimum number of statements, handle separately
        if (!requestsToUpdate.isEmpty()) {
            update requestsToUpdate;
        }
        if (!sampleOutsToUpdate.isEmpty()) {
            update sampleOutsToUpdate;
        }
    }

    
    public static void updateTATFields(List<Lead> leads, Map<Id, Lead> oldLeads){
        
        
        Map<String, String> statusFieldMap = new Map<String, String>{
            'Open' => 'Open_Date_Time_Capture__c',
                'Contacted' => 'Contacted_Date_Time_Capture__c',
                'Unqualified' => 'Unqualified_Date_Time_Capture__c',
                'Qualified' => 'Converted_Date_Time_Capture__c'
                };
                    
                    for (Lead lead : leads) 
                {
                    Lead oldLead = oldLeads != null ? oldLeads.get(lead.Id) : null;
                    if (statusFieldMap.containsKey(lead.Status) && 
                        (oldLead == null || lead.Status != oldLead.Status)) {
                            String fieldName = statusFieldMap.get(lead.Status);
                            lead.put(fieldName, DateTime.now());
                        }
                }
    }
    
    
}