@isTest
public class EnhancedCustomLookupTest {

    @isTest
    static void testFindRecordsWithAccount() {
        // Create test Account
        Account acc = new Account(Name = 'Test Lookup Account');
        insert acc;

        Test.startTest();
        List<SObject> results = EnhancedCustomLookup.findRecords(
            'Test',
            'Account',
            null,
            'Industry',
            new List<String>{'Name'},
            'Type',
            null,
            'Name',
            '5'
        );
        Test.stopTest();

    }

    @isTest
    static void testFindRecordsWithCase() {
        // Create test Case
        Case c = new Case(Subject = 'Lookup Test Case');
        insert c;

        Test.startTest();
        List<SObject> results = EnhancedCustomLookup.findRecords(
            '000', // assuming a CaseNumber starting pattern (generated auto)
            'Case',
            null,
            '',
            new List<String>{'CaseNumber'},
            '',
            null,
            null,
            '5'
        );
        Test.stopTest();

      
    }

    @isTest
    static void testFindRecordsWithFilterAndSort() {
        Account acc = new Account(Name = 'Sorted Filtered Account', Industry = 'Tech');
        insert acc;

        Test.startTest();
        List<SObject> results = EnhancedCustomLookup.findRecords(
            'Sorted',
            'Account',
            null,
            'Industry',
            new List<String>{'Name'},
            null,
            'Industry = \'Tech\'',
            'Name',
            '10'
        );
        Test.stopTest();

    }

    @isTest
    static void testFetchDefaultRecordForAccount() {
        Account acc = new Account(Name = 'Default Fetch Account');
        insert acc;

        Test.startTest();
        SObject result = EnhancedCustomLookup.fetchDefaultRecord(
            acc.Id,
            'Account',
            'Industry'
        );
        Test.stopTest();

       
    }

    @isTest
    static void testFetchDefaultRecordForCase() {
        Case c = new Case(Subject = 'Fetch Case Test');
        insert c;

        Test.startTest();
        SObject result = EnhancedCustomLookup.fetchDefaultRecord(
            c.Id,
            'Case',
            ''
        );
        Test.stopTest();

        
    }
}