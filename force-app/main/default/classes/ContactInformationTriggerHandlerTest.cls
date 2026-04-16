@isTest
public class ContactInformationTriggerHandlerTest {
    @isTest
    static void testMapCurrencyIsoCode() {
        // Create a test Lead with CurrencyIsoCode
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            CurrencyIsoCode = 'USD'
        );
        insert testLead;
        
        // Create test Contact_Information__c records related to the Lead
        Contact_Information__c testContactInfo = new Contact_Information__c(
            Lead__c = testLead.Id
        );
        insert testContactInfo;
        
        // Query inserted record to verify initial state
        testContactInfo = [SELECT Id, Lead__c, CurrencyIsoCode FROM Contact_Information__c WHERE Id = :testContactInfo.Id];
      //  System.assertEquals(null, testContactInfo.CurrencyIsoCode, 'CurrencyIsoCode should be null before the method execution');
        
        // Call the method
        Test.startTest();
        ContactInformationTriggerHandler.mapCurrencyIsoCode(new List<Contact_Information__c>{testContactInfo});
        Test.stopTest();
        
        // Verify that the CurrencyIsoCode was mapped correctly
        System.assertEquals('USD', testContactInfo.CurrencyIsoCode, 'CurrencyIsoCode should be mapped from the related Lead');
    }
}