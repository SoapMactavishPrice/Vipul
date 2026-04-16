public class ContactTriggerHandler {
    
    public static void updateContactAddresses(List<Contact> newContacts) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> areaIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        for (Contact contact : newContacts) {
            if (contact.Pin_Code__c != null) {
                postalCodeIds.add(contact.Pin_Code__c);
            }
            if (contact.Area__c != null) {
                areaIds.add(contact.Area__c);
            }
            if (contact.City__c != null) {
                cityIds.add(contact.City__c);
            }
            if (contact.State__c != null) {
                stateIds.add(contact.State__c);
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
        
        for (Contact contact : newContacts) {
            if (contact.Pin_Code__c != null && postalCodeMap.containsKey(contact.Pin_Code__c)) {
                Pin_Code__c postalCode = postalCodeMap.get(contact.Pin_Code__c);
                contact.Area__c = postalCode.Area__c;
                contact.City__c = postalCode.Area__r.City__c;
                contact.State__c = postalCode.Area__r.City__r.State__c;
                contact.Country__c = postalCode.Area__r.City__r.State__r.Country__c;
            } else if (contact.Area__c != null && areaMap.containsKey(contact.Area__c)) {
                Area__c area = areaMap.get(contact.Area__c);
                contact.City__c = area.City__c;
                contact.State__c = area.City__r.State__c;
                contact.Country__c = area.City__r.State__r.Country__c;
            } else if (contact.City__c != null && cityMap.containsKey(contact.City__c)) {
                City__c city = cityMap.get(contact.City__c);
                contact.State__c = city.State__c;
                contact.Country__c = city.State__r.Country__c;
            } else if (contact.State__c != null && stateMap.containsKey(contact.State__c)) {
                State__c state = stateMap.get(contact.State__c);
                contact.Country__c = state.Country__c;
            }
        }
    }
    
    public static void handleAfterInsert(List<Contact> newContacts) {
        
        if (newContacts == null || newContacts.isEmpty()) {
            return;
        }
        
        // Map AccountId → first Contact
        Map<Id, Id> accountToContactIdMap = new Map<Id, Id>();
        
        for (Contact con : newContacts) {
            if (con.AccountId != null && !accountToContactIdMap.containsKey(con.AccountId)) {
                accountToContactIdMap.put(con.AccountId, con.Id);
            }
        }
        
        if (accountToContactIdMap.isEmpty()) {
            return;
        }
        
        // Re-query Contacts with required fields
        Map<Id, Contact> contactMap = new Map<Id, Contact>([
            SELECT Id, FirstName, LastName, Email, MobilePhone, 
            Job_Title_Designation__c, AccountId
            FROM Contact
            WHERE Id IN :accountToContactIdMap.values()
        ]);
        
        // Query existing Account data
        Map<Id, Account> existingAccounts = new Map<Id, Account>([
            SELECT Id, Contact__c, Contact_Name__c, Contact_s_Email__c, 
            Contact_s_Mobile__c, Contact_First_Name__c, Designation__c
            FROM Account 
            WHERE Id IN :accountToContactIdMap.keySet()
        ]);
        
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Id accId : accountToContactIdMap.keySet()) {
            
            Contact con = contactMap.get(accountToContactIdMap.get(accId));
            Account existingAcc = existingAccounts.get(accId);
            
            if (con == null || existingAcc == null) continue;
            
            Account accToUpdate = new Account(Id = accId);
            
            // Primary Contact
            if (existingAcc.Contact__c == null) {
                accToUpdate.Contact__c = con.Id;
            }
            
            // Full Name
            if (String.isBlank(existingAcc.Contact_Name__c)) {
                accToUpdate.Contact_Name__c = con.LastName;
            }
            
            // Email
            if (String.isBlank(existingAcc.Contact_s_Email__c)) {
                accToUpdate.Contact_s_Email__c = con.Email;
            }
            
            // Mobile
            if (String.isBlank(existingAcc.Contact_s_Mobile__c)) {
                accToUpdate.Contact_s_Mobile__c = con.MobilePhone;
            }
            
            // ✅ First Name Sync
            if (String.isBlank(existingAcc.Contact_First_Name__c) && String.isNotBlank(con.FirstName)) {
                accToUpdate.Contact_First_Name__c = con.FirstName;
            }
            
            // ✅ Designation Sync
            if (String.isBlank(existingAcc.Designation__c) && String.isNotBlank(con.Job_Title_Designation__c)) {
                accToUpdate.Designation__c = con.Job_Title_Designation__c;
            }
            
            // Add only if something changed
            if (accToUpdate.getPopulatedFieldsAsMap().size() > 1) {
                accountsToUpdate.add(accToUpdate);
            }
        }
        
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    
}