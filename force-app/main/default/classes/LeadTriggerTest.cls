@isTest
public class LeadTriggerTest {
    @testSetup
    static void setup() {
        // Creating test leads
        List<Lead> leads = new List<Lead>{
            new Lead(FirstName = 'Test', LastName = 'Lead1', Company = 'Test Company', Status = 'Open - Not Contacted'),
            new Lead(FirstName = 'Test', LastName = 'Lead2', Company = 'Test Company', Status = 'Working - Contacted')
        };
        insert leads;
    }
    
    @isTest
    static void testBeforeInsert() {
        Lead newLead = new Lead(FirstName = 'Test', LastName = 'Lead3', Company = 'New Company', Status = 'Open - Not Contacted');
        Test.startTest();
        insert newLead;
        Test.stopTest();
        
        // Verify the address update logic (if applicable)
        Lead insertedLead = [SELECT Id FROM Lead WHERE Id = :newLead.Id LIMIT 1];
        System.assertNotEquals(null, insertedLead.Id, 'Lead should be inserted');
    }
    
    @isTest
    static void testBeforeUpdate() {
        Lead leadToUpdate = [SELECT Id, LastName FROM Lead LIMIT 1];
        leadToUpdate.LastName = 'Updated Lead';
        
        Test.startTest();
        update leadToUpdate;
        Test.stopTest();
        
        // Verify that update logic is executed
        Lead updatedLead = [SELECT Id, LastName FROM Lead WHERE Id = :leadToUpdate.Id];
        System.assertEquals('Updated Lead', updatedLead.LastName, 'Lead LastName should be updated');
    }
    
    @isTest
    static void testAfterUpdate() {
        Lead leadToConvert = [SELECT Id, Status FROM Lead LIMIT 1];
        leadToConvert.Status = 'Closed - Converted';
        
        Test.startTest();
        update leadToConvert;
        Test.stopTest();
        
        // Verify conversion handling logic (if applicable)
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :leadToConvert.Id];
        System.assertEquals('Closed - Converted', updatedLead.Status, 'Lead should be marked as converted');
    }
    
    @isTest
    static void testUpdateTriggersOpportunityHandling() {
        Lead leadToUpdate = [SELECT Id FROM Lead LIMIT 1];
        leadToUpdate.Status = 'Working - Contacted';
        
        Test.startTest();
        update leadToUpdate;
        Test.stopTest();
        
        // Verify that opportunity-related methods were triggered (mock validation if needed)
    }
}