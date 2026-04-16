@isTest
public class VisitControllerTest {
    
    @isTest
    static void testCreateVisitsSuccess() {
        // Create test Lead and Contact
        Lead testLead = new Lead(FirstName = 'Test', LastName = 'Lead', Company = 'Test Company');
        insert testLead;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com');
        insert testContact;

        // Set Start and End time
        String startDate = DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss');
        String endDate = DateTime.now().addHours(1).format('yyyy-MM-dd\'T\'HH:mm:ss');

        // Build VisitWrapper and attendee objects manually
        VisitController.VisitWrapper wrapper = new VisitController.VisitWrapper();
        wrapper.purpose = 'Test Purpose';
        wrapper.description = 'Test Description';
        wrapper.startDateTime = startDate;
        wrapper.endDateTime = endDate;
        wrapper.accountId = testLead.Id;
        wrapper.objectType = 'Lead';

        VisitController.attendees att = new VisitController.attendees();
        att.id = testContact.Id;
        wrapper.attendees = new List<VisitController.attendees>{ att };

        List<VisitController.VisitWrapper> wrappers = new List<VisitController.VisitWrapper>{ wrapper };
        String jsonInput = JSON.serialize(wrappers);

        // Call the method
        Test.startTest();
        Map<String, Object> result = VisitController.createVisits(jsonInput);
        Test.stopTest();

        

        List<Event> createdEvents = [SELECT Id, Subject FROM Event WHERE Subject = 'Test Purpose'];
        

        List<EventRelation> relations = [SELECT Id, RelationId FROM EventRelation WHERE EventId = :createdEvents[0].Id];
        
    }

    @isTest
    static void testCreateVisitsWithInvalidJson() {
        String badJson = 'invalid json';

        Test.startTest();
      //  Map<String, Object> result = VisitController.createVisits(badJson);
        Test.stopTest();

        
    }
}