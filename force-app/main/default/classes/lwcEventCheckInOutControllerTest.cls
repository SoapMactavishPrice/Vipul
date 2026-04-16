@isTest
public class lwcEventCheckInOutControllerTest {
    
    @testSetup
    static void setupData() {
        // Create a sample Event record for testing
        Event ev = new Event(
            Subject = 'Test Event',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1)
        );
        insert ev;
    }

    @isTest
    static void testUpdateCheckIn_Success() {
        Event ev = [SELECT Id FROM Event LIMIT 1];
        Test.startTest();
        String result = lwcEventCheckInOutController.updateCheckIn(ev.Id, 12.34, 56.78);
        Test.stopTest();

        Event updatedEvent = [SELECT Check_In_Time__c FROM Event WHERE Id = :ev.Id];
    }

    @isTest
    static void testUpdateCheckIn_AlreadyCheckedIn() {
        Event ev = [SELECT Id FROM Event LIMIT 1];
        // Manually check in first
        ev.Check_In_Time__c = System.now();
        update ev;

        Test.startTest();
        String result = lwcEventCheckInOutController.updateCheckIn(ev.Id, 12.34, 56.78);
        Test.stopTest();
    }

    @isTest
    static void testUpdateEventRecord() {
        Event ev = [SELECT Id FROM Event LIMIT 1];
        Test.startTest();
        String result = lwcEventCheckInOutController.updateEventRecord(ev.Id, 1.23, 4.56);
        Test.stopTest();
    }

    @isTest
    static void testUpdateCheckOut() {
        Event ev = [SELECT Id FROM Event LIMIT 1];
        Test.startTest();
        String result = lwcEventCheckInOutController.updateCheckOut(
            ev.Id,
            10.10,
            20.20,
            'Completed',
            'Test Description',
            'Positive feedback',
            'Follow-up call',
            Date.today()
        );
        Test.stopTest();
        System.assertEquals('Success', result);

        Event updated = [SELECT Check_Out_Time__c FROM Event WHERE Id = :ev.Id];
    }

    @isTest
    static void testGetEventById() {
        Event ev = [SELECT Id FROM Event LIMIT 1];
        Test.startTest();
        Event result = lwcEventCheckInOutController.getEventById(ev.Id);
        Test.stopTest();
    }

    @isTest
    static void testUpdateEventById() {
        Event ev = [SELECT Id FROM Event LIMIT 1];

        Map<String, Object> formData = new Map<String, Object>{
            'Visit_Result__c' => 'Visited',
            'Description' => 'Updated via LWC',
            'Client_Feedback_Or_Insights__c' => 'Very Interested',
            'Action_To_Do__c' => 'Send Proposal'
        };

        Test.startTest();
        Event updated = lwcEventCheckInOutController.updateEventById(ev.Id, formData);
        Test.stopTest();

    }
}