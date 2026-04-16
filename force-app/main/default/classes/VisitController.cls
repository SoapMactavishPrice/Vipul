// public with sharing class VisitController {
//     @AuraEnabled
//     public static void createVisits(List<VisitWrapper> events) {
//         List<Event> eventList = new List<Event>();

//         for (VisitWrapper vw : events) {
//             Event e = new Event();
//             e.Subject = vw.purpose;
//             e.Description = vw.description;

//             // Convert startDateTime and endDateTime from String to Datetime
//             if (vw.startDateTime != null) {
//                 e.StartDateTime = DateTime.parse(vw.startDateTime);
//             }
//             if (vw.endDateTime != null) {
//                 e.EndDateTime = DateTime.parse(vw.endDateTime);
//             }

//             // Assign Lead or Account ID appropriately
//             if (vw.objectType == 'Lead') {
//                 e.WhoId = vw.accountId;
//             } else if (vw.objectType == 'Account') {
//                 e.WhatId = vw.accountId;
//             }

//             eventList.add(e);
//         }

//         if (!eventList.isEmpty()) {
//             insert eventList;
//         }
//     }

//     // Wrapper class to receive data from LWC
//     public class VisitWrapper {
//         @AuraEnabled public String purpose;
//         @AuraEnabled public String description;
//         @AuraEnabled public String startDateTime;
//         @AuraEnabled public String endDateTime;
//         @AuraEnabled public String accountId;
//         @AuraEnabled public String objectType;
//     }
// }
public with sharing class VisitController {
    @AuraEnabled
    public static map<string,object> createVisits(String events) {
        List<VisitWrapper> visitWrapperList = parseJsonData(events);
        List<Event> eventList = new List<Event>();
        List<String> createdEventIds = new List<String>(); // To store created event Ids

        List<EventRelation> eventAttendees = new List<EventRelation>();
          map<string,object> result = new  map<string,object>(); 
        
        try{
        for (VisitWrapper vw : visitWrapperList) {
            System.debug('vw: ' + vw);
            Event e = new Event();
            e.Subject = vw.purpose;
            e.Description = vw.description;
            
            if (vw.visitTitleId != null) {
                e.Visit_Title__c = vw.visitTitleId;
            }
            
            // Set WhoId or WhatId based on object type
            if (vw.objectType == 'Lead') {
                e.WhoId = vw.accountId;
            } else if (vw.objectType == 'Account') {
                e.WhatId = vw.accountId;
            }
            
            // Convert and clean StartDateTime
            system.debug('vw.startDateTime -->'+ vw.startDateTime);
            if (vw.startDateTime != null) {
                //String cleanedStart = vw.startDateTime.replace('T', ' ').split('\\.')[0];
                //e.StartDateTime = DateTime.valueOf(cleanedStart);
                
                e.StartDateTime = DateTime.valueOfGMT(String.valueOf(vw.StartDateTime).replace('T', ' '));
            }

            // Convert and clean EndDateTime
            if (vw.endDateTime != null) {
                //String cleanedEnd = vw.endDateTime.replace('T', ' ').split('\\.')[0];
                //e.EndDateTime = DateTime.valueOf(cleanedEnd);
                
                
                e.EndDateTime = DateTime.valueOfGMT(String.valueOf(vw.endDateTime).replace('T', ' '));
            }

            // Ensure StartDateTime is set
            if (e.StartDateTime == null) {
                e.StartDateTime = DateTime.now();
            }

            // If EndDateTime is missing, assume 30 mins duration
            if (e.EndDateTime == null) {
                e.EndDateTime = e.StartDateTime.addMinutes(30);
            }

            // Calculate DurationInMinutes
            Long durationMillis = e.EndDateTime.getTime() - e.StartDateTime.getTime();
            Integer durationInMinutes = (Integer)(durationMillis / (1000 * 60));
            e.DurationInMinutes = durationInMinutes;

            // Set ActivityDateTime (required for Lightning)
            e.ActivityDateTime = e.StartDateTime;

            // Add to list
            eventList.add(e);
        }
        
        
        

        // Insert and return created IDs
        if (!eventList.isEmpty()) {
            insert eventList;
            for (Event createdEvent : eventList) {
                createdEventIds.add(createdEvent.Id);
            }
        }
        
        Integer index = 0;
        for (VisitWrapper vw : visitWrapperList) {
            Event insertedEvent = eventList[index];
            index++;
            for(attendees attee : vw.attendees) {
                //Map<String, Object> mapAttendee = (Map<String, Object>) attendee;
                EventRelation er = new EventRelation();
                 er.EventId = insertedEvent.Id;
                er.RelationId =attee.id;
                
                eventAttendees.add(er);
            }

            
        
        }   
        
        Database.insert(eventAttendees, false);
        
        result.put('Message','Success');
        }catch(exception e){
            result.put('Message',e.getMessage());
        }
        return result;
    }

    public class VisitWrapper {
        @AuraEnabled public String purpose;
        @AuraEnabled public String description;
        @AuraEnabled public String startDateTime;
        @AuraEnabled public String endDateTime;
        @AuraEnabled public String accountId;
        @AuraEnabled public String objectType;
        @AuraEnabled public String visitTitleId; 
        @AuraEnabled public List<attendees> attendees;
    }
    
    public class attendees {
        public string id;
    }

    public static List<VisitWrapper> parseJsonData(String json) {
        return (List<VisitWrapper>) System.JSON.deserialize(json, List<VisitWrapper>.class);
    }
}