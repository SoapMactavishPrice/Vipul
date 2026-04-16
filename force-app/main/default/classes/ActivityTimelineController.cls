public with sharing class ActivityTimelineController {
    
    @AuraEnabled
    public static List<Task> getRecentActivities(String recordId) {
        return [
            SELECT Id, Subject, Status, Priority, CreatedDate, ActivityDate
            FROM Task
            WHERE WhoId = :recordId
            ORDER BY ActivityDate DESC
            LIMIT 50
        ];
    }
}