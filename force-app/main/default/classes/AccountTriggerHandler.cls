public class AccountTriggerHandler {
    
    public static void updateAccountAddresses(List<Account> newAccounts) {
        Set<Id> postalCodeIds = new Set<Id>();
        Set<Id> areaIds = new Set<Id>();
        Set<Id> cityIds = new Set<Id>();
        Set<Id> stateIds = new Set<Id>();
        
        // Collect all relevant IDs from the leads being processed
        for (Account acc : newAccounts) {
            if (acc.Pin_Code__c != null) {
                postalCodeIds.add(acc.Pin_Code__c);
            }
            if (acc.Area__c != null) {
                areaIds.add(acc.Area__c);
            }
            if (acc.City__c != null) {
                cityIds.add(acc.City__c);
            }
            if (acc.State__c != null) {
                stateIds.add(acc.State__c);
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
        
        // Update the acc fields based on the selected values
        for (Account acc : newAccounts) {
            if (acc.Pin_Code__c != null && postalCodeMap.containsKey(acc.Pin_Code__c)) {
                Pin_Code__c postalCode = postalCodeMap.get(acc.Pin_Code__c);
                acc.Area__c = postalCode.Area__c;
                acc.City__c = postalCode.Area__r.City__c;
                acc.State__c = postalCode.Area__r.City__r.State__c;
                acc.Country__c = postalCode.Area__r.City__r.State__r.Country__c;
            } else if (acc.Area__c != null && areaMap.containsKey(acc.Area__c)) {
                Area__c area = areaMap.get(acc.Area__c);
                acc.City__c = area.City__c;
                acc.State__c = area.City__r.State__c;
                acc.Country__c = area.City__r.State__r.Country__c;
            } else if (acc.City__c != null && cityMap.containsKey(acc.City__c)) {
                City__c city = cityMap.get(acc.City__c);
                acc.State__c = city.State__c;
                acc.Country__c = city.State__r.Country__c;
            } else if (acc.State__c != null && stateMap.containsKey(acc.State__c)) {
                State__c state = stateMap.get(acc.State__c);
                acc.Country__c = state.Country__c;
            }
        }
        
    }
    
    public static void createAddressInformation(List<Account> newAccounts) {
        
        if (UserInfo.getName() == 'Integration API') {
            return;
        }
        
        if (newAccounts == null || newAccounts.isEmpty()) {
            return;
        }
        
        // Fetch the RecordType IDs for "Bill To" and "Ship To"
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.SObjectType.Address_Information__c.getRecordTypeInfosByName();
        Id billToRecordTypeId = recordTypeInfoMap.get('Bill To') != null ? recordTypeInfoMap.get('Bill To').getRecordTypeId() : null;
        Id shipToRecordTypeId = recordTypeInfoMap.get('Ship To') != null ? recordTypeInfoMap.get('Ship To').getRecordTypeId() : null;
        
        if (billToRecordTypeId == null || shipToRecordTypeId == null) {
            System.debug('Error: Required record types not found for Address_Information__c');
            return;
        }
        
        List<Address_Information__c> addressList = new List<Address_Information__c>();
        
        for (Account acc : newAccounts) {
            // Create "Bill To" address
            Address_Information__c billToAddress = new Address_Information__c();
            billToAddress.Street__c = acc.Street__c;
            billToAddress.Country__c = acc.Country__c;
            billToAddress.State__c = acc.State__c;
            billToAddress.City__c = acc.City__c;
            billToAddress.Area__c = acc.Area__c;
            billToAddress.Pin_Code__c = acc.Pin_Code__c;
            billToAddress.District__c = acc.District__c;
            billToAddress.RecordTypeId = billToRecordTypeId;
            billToAddress.Account__c = acc.Id;
            
            // Create "Ship To" address (same fields, can be customized if needed)
            Address_Information__c shipToAddress = new Address_Information__c();
            shipToAddress.Street__c = acc.Street__c;
            shipToAddress.Country__c = acc.Country__c;
            shipToAddress.State__c = acc.State__c;
            shipToAddress.City__c = acc.City__c;
            shipToAddress.Area__c = acc.Area__c;
            shipToAddress.Pin_Code__c = acc.Pin_Code__c;
            shipToAddress.District__c = acc.District__c;
            shipToAddress.RecordTypeId = shipToRecordTypeId;
            shipToAddress.Account__c = acc.Id;
            
            addressList.add(billToAddress);
            addressList.add(shipToAddress);
        }
        
        if (!addressList.isEmpty()) {
            try {
                insert addressList;
            } catch (DmlException e) {
                System.debug('Error inserting Address_Information__c records: ' + e.getMessage());
            }
        }
    }

    
    
    public static void handleAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountMap) {
        System.debug('Handler method called');
        
        // List to hold Opportunities to be updated
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        // Loop through the updated Accounts
        for (Account acc : newAccounts) {
            // Get the old Account record
            Account oldAcc = oldAccountMap.get(acc.Id);

            // Check if the INCO_Terms__c field has changed
            System.debug('Checking INCO_Terms__c for Account: ' + acc.Id);
            System.debug('Old INCO_Terms__c: ' + oldAcc.INCO_Terms__c + ', New INCO_Terms__c: ' + acc.INCO_Terms__c);
            if (acc.INCO_Terms__c != oldAcc.INCO_Terms__c) {
                System.debug('INCO_Terms__c has changed for Account: ' + acc.Id);
                
                // Query related Opportunities
                List<Opportunity> relatedOpps = [SELECT Id, INCO_Terms__c FROM Opportunity WHERE AccountId = :acc.Id];
                System.debug('Related Opportunities: ' + relatedOpps);

                // Update the INCO_Terms__c field on each related Opportunity
                for (Opportunity opp : relatedOpps) {
                    System.debug('Updating Opportunity: ' + opp.Id + ' with INCO_Terms__c: ' + acc.INCO_Terms__c);
                    opp.INCO_Terms__c = acc.INCO_Terms__c;
                    oppsToUpdate.add(opp);
                }
            }
        }

        // Update the Opportunities
        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
            System.debug('Updated Opportunities: ' + oppsToUpdate);
        }
    }
    
    
    public static void handleAfterInsert(List<Account> newAccounts) {
        System.debug('handleAfterInsert called with Accounts: ' + newAccounts);
        
        // List to hold Opportunities to be updated
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        // Loop through the newly inserted Accounts
        for (Account acc : newAccounts) {
            System.debug('Processing Account: ' + acc);
            
            // Query related Opportunities
            List<Opportunity> relatedOpps = [SELECT Id, Inco_Terms__c, AccountId FROM Opportunity WHERE AccountId = :acc.Id];
            System.debug('Related Opportunities for Account ' + acc.Id + ': ' + relatedOpps);
            
            // Check if related opportunities are found
            if (relatedOpps.isEmpty()) {
                System.debug('No related opportunities found for Account ' + acc.Id);
            }
            
            // Update the Inco_Terms__c field on each related Opportunity
            for (Opportunity opp : relatedOpps) {
                System.debug('Updating Opportunity: ' + opp.Id + ' with Inco_Terms__c: ' + acc.Inco_Terms__c);
                opp.Inco_Terms__c = acc.Inco_Terms__c; // Ensure field names match
                oppsToUpdate.add(opp);
            }
        }
        
        // Update the Opportunities
        if (!oppsToUpdate.isEmpty()) {
            System.debug('Updating Opportunities: ' + oppsToUpdate);
            update oppsToUpdate;
        } else {
            System.debug('No Opportunities to update.');
        }
    }
    
    
    public static void populateContactDetails(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Set<Id> contactIdsToQuery = new Set<Id>();

        for (Account acc : newAccounts) {
            Account oldAcc = oldMap != null ? oldMap.get(acc.Id) : null;

            // Only act if Contact__c is newly set or changed
            if (acc.Contact__c != null && (oldAcc == null || acc.Contact__c != oldAcc.Contact__c)) {
                contactIdsToQuery.add(acc.Contact__c);
            }
        }

        if (contactIdsToQuery.isEmpty()) return;

        Map<Id, Contact> contactMap = new Map<Id, Contact>([
            SELECT Id, FirstName, LastName, Email, MobilePhone, Job_Title_Designation__c
            FROM Contact
            WHERE Id IN :contactIdsToQuery
        ]);

        for (Account acc : newAccounts) {
            if (acc.Contact__c != null && contactMap.containsKey(acc.Contact__c)) {
                Contact con = contactMap.get(acc.Contact__c);
                
                // First Name sync
                if (String.isBlank(acc.Contact_First_Name__c)) {
                    acc.Contact_First_Name__c = con.FirstName;
                }
                
                // Designation sync
                if (String.isBlank(acc.Designation__c)) {
                    acc.Designation__c = con.Job_Title_Designation__c;
                }

                // Populate fields only if they are blank
                if (String.isBlank(acc.Contact_Name__c)) {
                    acc.Contact_Name__c = con.LastName;
                }

                if (String.isBlank(acc.Contact_s_Email__c)) {
                    acc.Contact_s_Email__c = con.Email;
                }

                if (String.isBlank(acc.Contact_s_Mobile__c)) {
                    acc.Contact_s_Mobile__c = con.MobilePhone;
                }
            }
        }
    }

    public static void createContacts(List<Account> accounts) {
        List<Contact> contactsToCreate = new List<Contact>();

        for (Account acc : accounts) {
            // Only create a new Contact if Contact__c is NOT set
            if (acc.Contact__c == null &&
                String.isNotBlank(acc.Contact_Name__c) &&
                String.isNotBlank(acc.Contact_s_Email__c) &&
                String.isNotBlank(acc.Contact_s_Mobile__c)) {

                Contact newContact = new Contact(
                    LastName = acc.Contact_Name__c,
                    FirstName = acc.Contact_First_Name__c,
                    Job_Title_Designation__c = acc.Designation__c,
                    Email = acc.Contact_s_Email__c,
                    MobilePhone = acc.Contact_s_Mobile__c,
                    AccountId = acc.Id,
                    CurrencyIsoCode = acc.CurrencyIsoCode
                );
                contactsToCreate.add(newContact);
            }
        }

        if (!contactsToCreate.isEmpty()) {
            insert contactsToCreate;

            // Map newly created Contacts back to Accounts
            Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
            for (Contact con : contactsToCreate) {
                accountIdToContact.put(con.AccountId, con);
            }
            
            List<Account> accountsToUpdate = new List<Account>();
            for (Account acc : accounts) {
                if (acc.Contact__c == null && accountIdToContact.containsKey(acc.Id)) {
                    Account accToUpdate = new Account(
                        Id = acc.Id,
                        Contact__c = accountIdToContact.get(acc.Id).Id
                    );
                    accountsToUpdate.add(accToUpdate);
                }
            }
            
            
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
        }
    }
    
    public static void setSalesEmployeeCode(List<Account> newAccounts, Map<Id, Account> oldMap) {
        
        Set<Id> ownerIds = new Set<Id>();
        
        for (Account acc : newAccounts) {
            Account oldAcc = oldMap != null ? oldMap.get(acc.Id) : null;
            
            // Run only if owner changed or insert
            if (acc.OwnerId != null &&
                (oldAcc == null || acc.OwnerId != oldAcc.OwnerId)) {
                    ownerIds.add(acc.OwnerId);
                }
        }
        
        if (ownerIds.isEmpty()) return;
        
        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, EmployeeNumber
            FROM User
            WHERE Id IN :ownerIds
        ]);
        
        for (Account acc : newAccounts) {
            Account oldAcc = oldMap != null ? oldMap.get(acc.Id) : null;
            
            if (acc.OwnerId != null &&
                (oldAcc == null || acc.OwnerId != oldAcc.OwnerId) &&
                userMap.containsKey(acc.OwnerId)) {
                    
                    User u = userMap.get(acc.OwnerId);
                    
                    if (String.isNotBlank(u.EmployeeNumber)) {
                        acc.Sales_Employee_Code__c = u.EmployeeNumber;
                    }
                }
        }
    }
}