@isTest
public with sharing class CreateTaskTest {
    @testSetup
    static void setupTestData() {
        // Create test users
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testusertest@example.com',
            Username = 'testusertest@example.com.salesforce',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Create test Account with allowed currency
        Account testAccount = new Account(Name = 'Test Account', INCO_Terms__c = 'DDP', CurrencyIsoCode = 'USD', OwnerId = testUser.Id);
        insert testAccount;
        
        // Create test Contact with allowed currency
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id, CurrencyIsoCode = 'USD', OwnerId = testUser.Id);
        insert testContact;
        
        // Create test Lead
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Lead', Company = 'Test Company');
        insert testLead;
        
        // Create test Task
        Task testTask = new Task(
            Subject = 'Test Task',
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = Date.today(),
            WhatId = testAccount.Id,
            WhoId = testContact.Id,
            OwnerId = testUser.Id
        );
        insert testTask;
    }
    
    @isTest
    static void testGetCurrentUserName() {
        Test.startTest();
        Map<String, String> result = CreateTask.getCurrentUserName();
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetUsers() {
        Test.startTest();
        List<User> users = CreateTask.getUsers();
        Test.stopTest();
        System.assert(users.size() > 0);
    }
    
    @isTest
    static void testAddTask() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        User usr = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        
        System.runAs(usr) {
            Test.startTest();
            CreateTask.addTask('New Test Task', DateTime.now(), 'High', acc.Id, usr.Id, con.Id);
            Test.stopTest();
            
            Task insertedTask = [SELECT Id, Subject FROM Task WHERE Subject = 'New Test Task' LIMIT 1];
        }
    }
    
    @isTest
    static void testGetTasks() {
        Test.startTest();
        List<Task> tasks = CreateTask.getTasks();
        Test.stopTest();
    }
    
    @isTest
    static void testMarkTaskAsCompleted() {
        Task t = new Task(
            Subject = 'Test Task',
            Status = 'Not Started',
            Priority = 'Normal',
            WhatId = null, // Avoid linking to Lead if possible
            OwnerId = UserInfo.getUserId()
        );
        insert t;
        
        Test.startTest();
       // CreateTask.markTaskAsCompleted(t.Id);
        Test.stopTest();
        
        Task updatedTask = [SELECT Id, Status FROM Task WHERE Id = :t.Id];
    }

    
    @isTest
    static void testSearchLeads() {
        Test.startTest();
        List<Lead> leads = CreateTask.searchLeads('Test');
        Test.stopTest();
    }
    
    @isTest
    static void testSearchAccounts() {
        Test.startTest();
        List<Account> accounts = CreateTask.searchAccounts('Test');
        Test.stopTest();
    }
    
    @isTest
    static void testSearchContacts() {
        Test.startTest();
        List<Contact> contacts = CreateTask.searchContacts('Test');
        Test.stopTest();
    }
}