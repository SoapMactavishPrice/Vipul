@isTest
public class AccountTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Accounts
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Test Account 1aew', Inco_Terms__c = 'EXW', Contact_Name__c = 'John23321 Doe', Contact_s_Mobile__c = '1323114232', Contact_s_Email__c = 'johnssewdsed12@example.com', CurrencyIsoCode = 'USD'),
            new Account(Name = 'Test Account 2ewws', Inco_Terms__c = 'EXW', CurrencyIsoCode = 'USD') // No contact info
        };
        insert accounts;

        // Create Opportunities related to the first Account
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(Name = 'Opp 1', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = accounts[0].Id),
            new Opportunity(Name = 'Opp 2', StageName = 'Qualification', CloseDate = Date.today().addDays(60), AccountId = accounts[0].Id)
        };
        insert opps;
    }

    @isTest
    static void testUpdateAccountAddresses() {
        
          Country__c testCountry = new Country__c(Name = 'India');
        insert testCountry;
        
        State__c testState = new State__c(Name = 'Test State', Country__c = testCountry.Id);
        insert testState;
        
        City__c testCity = new City__c(Name = 'Test City', State__c = testState.Id);
        insert testCity;
        
        Area__c testArea = new Area__c(Name = 'Test Area', City__c = testCity.Id);
        insert testArea;
        
        Pin_Code__c testPostalCode = new Pin_Code__c(Name = '12345', Area__c = testArea.Id);
        insert testPostalCode;
        
        
        Account acc1 = new Account(Name = 'Test Account 1', Street__c = '123 Test St', City__c = testCity.id, State__c = testState.id, Country__c = testCountry.id, Pin_Code__c = testPostalCode.Id, INCO_Terms__c = 'DDP', currencyisocode='USD');
        Account acc2 = new Account(Name = 'Test Account 2', Street__c = '456 Test Ave', City__c = testCity.id, State__c = testState.id, Country__c = testCountry.id, Pin_Code__c = testPostalCode.id,INCO_Terms__c = 'DDP', currencyisocode='USD');
        insert new List<Account>{acc1, acc2};
        
        Test.startTest();
        List<Account> newAccounts = [SELECT Id, Street__c, City__c,Area__c,District__c, State__c, Country__c, Pin_Code__c FROM Account WHERE Id IN :new Set<Id>{acc1.Id, acc2.Id}];
        AccountTriggerHandler.createAddressInformation(newAccounts);
        Test.stopTest();
    }

    
    
    @isTest
    static void testCreateAddressInformation() {
        
          Country__c testCountry = new Country__c(Name = 'India');
        insert testCountry;
        
        State__c testState = new State__c(Name = 'Test State', Country__c = testCountry.Id);
        insert testState;
        
        City__c testCity = new City__c(Name = 'Test City', State__c = testState.Id);
        insert testCity;
        
        Area__c testArea = new Area__c(Name = 'Test Area', City__c = testCity.Id);
        insert testArea;
        
        Pin_Code__c testPostalCode = new Pin_Code__c(Name = '12345', Area__c = testArea.Id);
        insert testPostalCode;
        
        
        Account acc1 = new Account(Name = 'Test Account 1', Street__c = '123 Test St', City__c = testCity.id, State__c = testState.id, Country__c = testCountry.id, Pin_Code__c = testPostalCode.Id, INCO_Terms__c = 'DDP', currencyisocode='USD');
        Account acc2 = new Account(Name = 'Test Account 2', Street__c = '456 Test Ave', City__c = testCity.id, State__c = testState.id, Country__c = testCountry.id, Pin_Code__c = testPostalCode.id, INCO_Terms__c = 'DDP', currencyisocode='USD');
        insert new List<Account>{acc1, acc2};
        
        Test.startTest();
        List<Account> newAccounts = [SELECT Id, Street__c,Area__c,District__c, City__c, State__c, Country__c, Pin_Code__c FROM Account WHERE Id IN :new Set<Id>{acc1.Id, acc2.Id}];
        AccountTriggerHandler.createAddressInformation(newAccounts);
        Test.stopTest();
    }
    
    @isTest
    static void testHandleAfterUpdate() {
        Account acc1 = new Account(Name = 'Test Account 1', INCO_Terms__c = 'FOB',currencyisocode='USD');
        Account acc2 = new Account(Name = 'Test Account 2', INCO_Terms__c = 'CIF',currencyisocode='USD');
        insert new List<Account>{acc1, acc2};
        
       Opportunity opp1 = new Opportunity(
    Name = 'Opp1',
    AccountId = acc1.Id,
    INCO_Terms__c = 'EXW',
    StageName = 'Prospecting',  // Add a valid StageName value
    CloseDate = Date.today().addDays(30)  // Add a valid CloseDate (e.g., 30 days from today)
       );
        
        Opportunity opp2 = new Opportunity(
            Name = 'Opp2',
            AccountId = acc2.Id,
            INCO_Terms__c = 'DDP',
            StageName = 'Prospecting',  // Add a valid StageName value
            CloseDate = Date.today().addDays(30)  // Add a valid CloseDate (e.g., 30 days from today)
        );
        
        insert new List<Opportunity>{opp1, opp2};

        
        acc1.INCO_Terms__c = 'EXW';
        acc2.INCO_Terms__c = 'DDP';
        update new List<Account>{acc1, acc2};
        
        Test.startTest();
        Map<Id, Account> oldAccountMap = new Map<Id, Account>([SELECT Id, INCO_Terms__c FROM Account WHERE Id IN :new Set<Id>{acc1.Id, acc2.Id}]);
        List<Account> newAccounts = [SELECT Id, INCO_Terms__c FROM Account WHERE Id IN :new Set<Id>{acc1.Id, acc2.Id}];
        //AccountTriggerHandler.handleAfterUpdate(newAccounts, oldAccountMap);
        Test.stopTest();
    }
    
   	@isTest
    static void testHandleAfterInsert() {
        // Fetch the inserted accounts
        List<Account> insertedAccounts = [SELECT Id, Inco_Terms__c FROM Account];

        Test.startTest();
        // Call the method to test
        AccountTriggerHandler.handleAfterInsert(insertedAccounts);
        Test.stopTest();

    }

    @isTest
    static void testCreateContacts() {
        // Fetch the inserted accounts
        List<Account> insertedAccounts1 = [SELECT Id, Contact_Name__c, Contact_s_Mobile__c, Contact_s_Email__c, CurrencyIsoCode FROM Account];

        Test.startTest();
        // Call the method to test
       // AccountTriggerHandler.createContacts(insertedAccounts1);
        Test.stopTest();

    }
}