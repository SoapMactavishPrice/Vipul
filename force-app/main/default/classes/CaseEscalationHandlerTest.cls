@isTest
public class CaseEscalationHandlerTest {

    @testSetup
    static void setupData() {
        // Create a test manager
        User managerUser = new User(
            FirstName = 'Manager',
            LastName = 'User',
            Email = 'manager@example.com',
            Username = 'manageruser@test.com.' + System.currentTimeMillis(),
            Alias = 'mgrusr',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert managerUser;

        // Create a test user with the above manager
        User testOwner = new User(
            FirstName = 'Case',
            LastName = 'Owner',
            Email = 'owner@example.com',
            Username = 'caseowner@test.com.' + System.currentTimeMillis(),
            Alias = 'cowner',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ManagerId = managerUser.Id
        );
        insert testOwner;
        
        // Create Contact
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'contact@example.com'
        );
        insert contact;
        
        // Create Unit_Master__c
        Unit_Master__c unit1 = new Unit_Master__c(
            Name = 'Unit 1',
            Email_1__c = 'unit1@example.com',
            Email_2__c = 'unit12@example.com',
            Email_3__c = 'unit13@example.com'
        );
        insert unit1;

        // Create an initial case (not escalated)
        Case testCase = new Case(
            Subject = 'Test Escalation Case',
            Priority = 'High',
            Status = 'New',
            IsEscalated = false,
            OwnerId = testOwner.Id,
            ContactId = contact.Id,  
            Plant__c = unit1.Id
        );
        insert testCase;
        
        // Create Responsible Persons
        List<Responsible_Person__c> responsiblePersons = new List<Responsible_Person__c>{
            new Responsible_Person__c(Name = 'Case RP', Email__c = 'case@example.com'),
            new Responsible_Person__c(Name = 'Corrective RP', Email__c = 'corrective@example.com'),
            new Responsible_Person__c(Name = 'Preventive RP', Email__c = 'preventive@example.com')
        };
        insert responsiblePersons;
    }

    @isTest
    static void testSendEscalationEmails() {
        // Fetch the existing case and user
        Case existingCase = [
            SELECT Id, IsEscalated, OwnerId, CaseNumber, Subject, Priority 
            FROM Case 
            LIMIT 1
        ];

        // Simulate a before-update map with old case data
        Map<Id, Case> oldCaseMap = new Map<Id, Case>();
        Case oldVersion = existingCase.clone(false, false, false, false);
        oldVersion.IsEscalated = false;
        oldCaseMap.put(existingCase.Id, oldVersion);

        // Update the case to set IsEscalated = true
        existingCase.IsEscalated = true;
        update existingCase;

        // Call the method to test
        Test.startTest();
        CaseEscalationHandler.sendEscalationEmails(new List<Case>{ existingCase }, oldCaseMap);
        Test.stopTest();        
    }
    
    @isTest
    static void testCaseCreationEmail() {
        // Fetch the inserted case
        Case c = [SELECT Id, ContactEmail, Plant__c, CaseNumber, Subject FROM Case LIMIT 1];
        
        Unit_Master__c unit = [SELECT Email_1__c, Email_2__c, Email_3__c, Email_4__c, Email_5__c, Email_6__c 
                                       FROM Unit_Master__c 
                                       WHERE Id = :c.Plant__c];

        Test.startTest();
        // Simulate trigger logic
        CaseEscalationHandler.sendEmailToContactAndPlant(c);
        Test.stopTest();

        // No asserts for email, but check no exceptions
    }
    
    @isTest
    static void testStatusChangeEmail() {
        // Fetch the inserted case
        Case c = [SELECT Id, Status, ContactEmail, Plant__c, Subject, CaseNumber FROM Case LIMIT 1];
        
        // Simulate status change
        c.Status = 'Complaint Lodge';
        update c;
        
        Test.startTest();
        CaseEscalationHandler.sendStatusChangeEmails(
            new List<Case>{c},
            new Map<Id, Case>{c.Id => new Case(Id = c.Id, Status = 'New')} // simulate old status
        );
        Test.stopTest();
    }
    
    
    @isTest
    static void testComplaintResolutionEmail() {
        // Fetch the inserted case
        Case c = [SELECT Id, Status, ContactEmail, Plant__c, Subject, CaseNumber FROM Case LIMIT 1];
        
        // Simulate status change to Complaint Resolution
        c.Status = 'Complaint Resolution';
        c.Responsible_Person__c = 'John Doe';
        c.Comments = 'Issue resolved successfully.';
        update c;
        
        Test.startTest();
        CaseEscalationHandler.sendStatusChangeEmails(
            new List<Case>{c},
            new Map<Id, Case>{c.Id => new Case(Id = c.Id, Status = 'In Progress')} // simulate old status
        );
        Test.stopTest();
    }
    
    @isTest
    static void testInsertCaseWithResponsiblePersons() {
        List<Responsible_Person__c> rps = [SELECT Id FROM Responsible_Person__c];

        Case c = new Case(
            Subject = 'Test Case Insert',
            Description = 'Initial Description',
            Case_Responsible_Person__c = rps[0].Id,
            Corrective_Responsible_Person__c = rps[1].Id,
            Preventive_Responsible_Person__c = rps[2].Id
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        // You can add assertions here if you log emails or use a custom object to track them
    }

}