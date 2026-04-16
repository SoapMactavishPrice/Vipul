public with sharing class CreateTask {
    
    // Method to get the current logged-in user's information
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getCurrentUserName() {
        Id currentUserId = UserInfo.getUserId();
        User currentUser = [SELECT Id, Name FROM User WHERE Id = :currentUserId LIMIT 1];
        
        Map<String, String> userInfo = new Map<String, String>();
        userInfo.put('Id', currentUser.Id); // User Id
        userInfo.put('Name', currentUser.Name); // User Name
        
        return userInfo; 
    }

    @AuraEnabled(cacheable=true)
    public static List<User> getUsers() {
        return [SELECT Id, Name FROM User];
    }
    
    // Method to add a new task with parameters (subject, due date, priority, related object, owner, and assigned user)
    @AuraEnabled
    public static void addTask(String subject, DateTime dueDateTime, String priority, Id whatId, Id ownerId, Id whoId) {
        // Create a new Task object
        Task newTask = new Task();
        
        // Set the properties for the new Task
        newTask.Subject = subject;
        newTask.Status = 'Not Started'; // Default status
        newTask.Priority = priority; // Set priority
        newTask.ActivityDate = dueDateTime.date(); // Ensure the field receives only a Date
        if (whatId != null) {
            newTask.WhatId = whatId; // Set the related record (Account)
        }
        if (whoId != null) {
            newTask.WhoId = whoId; // Set the related record (Lead/Contact)
        }
        newTask.OwnerId = ownerId; // Set the owner (selected user)
        
        // Insert the new Task
        insert newTask;
    }

    // Method to retrieve all tasks
    @AuraEnabled(cacheable=true)
    public static List<Task> getTasks() {
        // Retrieve all tasks (without filtering by status)
        List<Task> tasks = [SELECT Id, Subject, Status, Priority, ActivityDate FROM Task];
        return tasks;
    }

    // Method to mark a task as completed
    @AuraEnabled
    public static void markTaskAsCompleted(Id taskId) {
        // Retrieve the task by its Id
        Task task = [SELECT Id, Status FROM Task WHERE Id = :taskId LIMIT 1];
        
        // Mark the task as 'Completed'
        task.Status = 'Completed';
        
        // Update the task
        update task;
    }

    // Apex method to search for Leads based on search term
    @AuraEnabled(cacheable=true)
    public static List<Lead> searchLeads(String searchTerm) {
        return [SELECT Id, Name FROM Lead WHERE Name LIKE :('%' + searchTerm + '%') LIMIT 10];
    }

    // Apex method to search for Accounts based on search term
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchTerm) {
        return [SELECT Id, Name FROM Account WHERE Name LIKE :('%' + searchTerm + '%') LIMIT 10];
    }

    // Apex method to search for Contacts based on search term
    @AuraEnabled(cacheable=true)
    public static List<Contact> searchContacts(String searchTerm) {
        return [SELECT Id, Name FROM Contact WHERE Name LIKE :('%' + searchTerm + '%') LIMIT 10];
    }
}