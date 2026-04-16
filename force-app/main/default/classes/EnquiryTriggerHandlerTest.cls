@isTest
public class EnquiryTriggerHandlerTest {
    
    @isTest
    static void testHandleProposalOpportunities() {
                
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
        
        Id PID = Test.getStandardPricebookId();
        
        Product2 prod = new Product2();
        prod.name='Product A';
        prod.isActive=true;
        insert prod;
        
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = PID, 
            Product2Id = prod.Id,
            UnitPrice = 1000,
            IsActive = true);
        
        insert standardPrice;
        
        Account acc = new Account();
        acc.Name = 'Finesse';
        acc.CurrencyIsoCode = 'USD';
        acc.INCO_Terms__c = 'DDP';
        acc.Payment_Terms__c = '1';
        insert acc;
     
        

        Contact con = new Contact();
        con.AccountId = acc.id;
        con.FirstName = 'Prashant';
        con.LastName = 'Padal';
        con.Email = 'Prashantpadal@finessedirect.com';
        con.Phone = '123-456-7890';
        con.CurrencyIsoCode = 'USD';
        con.Country__c= testCountry.id;
        con.City__c=testCity.id;
        con.State__c=testState.id;
        con.Area__c=testArea.id;
        con.Street__c='MBP Road';
        con.Pin_Code__c=testPostalCode.id; 
        insert con;
        
      
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Finesse';
        opp.StageName = 'Sampling';
        opp.CloseDate = Date.today();
        opp.AccountId = acc.Id;
        opp.Contact__c = con.Id;
        opp.Pricebook2Id=PID;
        
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem
            (OpportunityId = opp.Id,
             pricebookentryid=standardPrice.id, 
             product2Id= prod.Id,
             UnitPrice = 1000, 
             Quantity = 1, 
             Discount=10);
        insert oli;
        System.debug('oli' +oli);
        
        
        opp.StageName = 'Proposal';
        update opp;
        
        
        
        Map<Id, Opportunity> oldOpportunityMap = new Map<Id, Opportunity>();
        oldOpportunityMap.put(opp.Id, new Opportunity(StageName = 'Sampling')); 
        
        List<Opportunity> newOpportunities = new List<Opportunity>{opp};
            
        Test.startTest();
          EnquiryTriggerHandler.handleProposalOpportunities(newOpportunities, oldOpportunityMap);
      //    EnquiryTriggerHandler.handleClosedWonOpportunities(newOpportunities, oldOpportunityMap);
    
        Test.stopTest();
 
        
    }
    
    @isTest
    static void testHandleCloseWonOpportunities() {
                
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
        
        Id PID = Test.getStandardPricebookId();
        
        Product2 prod = new Product2();
        prod.name='Product A';
        prod.isActive=true;
        insert prod;
        
        
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = PID, 
            Product2Id = prod.Id,
            UnitPrice = 1000,
            IsActive = true);
        
        insert standardPrice;
        
        Account acc = new Account();
        acc.Name = 'Finesse';
        acc.CurrencyIsoCode = 'USD';
        acc.INCO_Terms__c = 'DDP';
        acc.Payment_Terms__c = 'Advance';
        insert acc;
     
        

        Contact con = new Contact();
        con.AccountId = acc.id;
        con.FirstName = 'Prashant';
        con.LastName = 'Padal';
        con.Email = 'Prashantpadal@finessedirect.com';
        con.Phone = '123-456-7890';
        con.CurrencyIsoCode = 'USD';
        con.Country__c= testCountry.id;
        con.City__c=testCity.id;
        con.State__c=testState.id;
        con.Area__c=testArea.id;
        con.Street__c='MBP Road';
        con.Pin_Code__c=testPostalCode.id; 
        insert con;
        
      
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Finesse';
        opp.StageName = 'Sampling';
        opp.CloseDate = Date.today();
        opp.AccountId = acc.Id;
        opp.Contact__c = con.Id;
        opp.Pricebook2Id=PID;
        
        insert opp;

        OpportunityLineItem oli = new OpportunityLineItem
            (OpportunityId = opp.Id,
             pricebookentryid=standardPrice.id, 
             product2Id= prod.Id,
             UnitPrice = 1000, 
             Quantity = 1, 
             Discount=10);
        insert oli;
        System.debug('oli' +oli);
        
        Quote quo = new Quote();
        quo.Name = 'Test';
        quo.ContactId = con.id;
        quo.OpportunityId = opp.id;
        quo.ExpirationDate = System.Today();
        quo.PO_Date__c = System.Today();
        quo.PO_PI_Number__c = '123';
        insert quo;
        
        
        opp.StageName='Closed Won';
        update opp;
        
        
        Map<Id, Opportunity> oldOpportunityMap = new Map<Id, Opportunity>();
        oldOpportunityMap.put(opp.Id, new Opportunity(StageName = 'Sampling')); 
        
        List<Opportunity> newOpportunities = new List<Opportunity>{opp};
            
        Test.startTest();
         // EnquiryTriggerHandler.handleClosedWonOpportunities(newOpportunities, oldOpportunityMap);
    
        Test.stopTest();
 
        
    }

}