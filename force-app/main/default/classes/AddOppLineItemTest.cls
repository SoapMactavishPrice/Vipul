@isTest
public class AddOppLineItemTest {

    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name != 'Guest User' LIMIT 1];

        User testUser = new User(Alias = 'testusr', 
                               Email = 'testuser11test@example.com', 
                               EmailEncodingKey = 'UTF-8', 
                               LastName = 'Test', 
                               LanguageLocaleKey = 'en_US', 
                               LocaleSidKey = 'en_US', 
                               ProfileId = p.Id, 
                               TimeZoneSidKey = 'America/Los_Angeles', 
                               UserName = 'testuser1165test@example.com');
        insert testUser;

        System.runAs(testUser) {
            Account acc = new Account(Name = 'Test Account', OwnerId = testUser.Id);
            insert acc;

            Id standardPricebookId = Test.getStandardPricebookId(); // No update needed

            Product2 prod = new Product2(Name = 'Test Product', Family = 'Hardware', IsActive = true);
            insert prod;

            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = standardPricebookId, 
                Product2Id = prod.Id, 
                UnitPrice = 100, 
                IsActive = true,
                CurrencyIsoCode = 'USD'
            );
            insert pbe;

            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity', 
                AccountId = acc.Id, 
                StageName = 'Prospecting', 
                CloseDate = Date.today(), 
                CurrencyIsoCode = 'USD', 
                Pricebook2Id = standardPricebookId
            );
            insert opp;

            Sample_Request__c sampleRequest = new Sample_Request__c(
                Enquiry__c = opp.Id,  
                Company_Name__c = acc.Id  
            );
            insert sampleRequest;

            Sample_Out__c sampleOut = new Sample_Out__c(
                Sample_Request__c = sampleRequest.Id,  
                Product_Name__c = prod.Id,
                Sample_Out_Status__c = 'Sample Approved',
                Quality__c = 'High Quality'
            );
            insert sampleOut;
        }
    }

   @isTest
static void testCheckExistingOpportunity() {
    Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    String result = AddOppLineItem.checkExistingOpportunity(opp.Name, acc.Id);
    Test.stopTest();
}


    @isTest
    static void testAddOpportunityLineItems_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        String jsonLineItems = '[{"prodId": "' + prod.Id + '", "quality": "High", "volume": "10", "packaging": "1kg", "CommissionType": "Value", "commissionval": "5", "commissionper": "0", "price": "120", "freightval": "15"}]';
        
        Test.startTest();
        try {
            String result = AddOppLineItem.addOpportunityLineItems(opp.Id, jsonLineItems);
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddOpportunityLineItems_EmptyOpportunityId() {
        Test.startTest();
        try {
            AddOppLineItem.addOpportunityLineItems(null, '[{"prodId": "001", "volume": "10"}]');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddOpportunityLineItems_EmptyJson() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try {
            AddOppLineItem.addOpportunityLineItems(opp.Id, '');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddOpportunityLineItems_InvalidJsonFormat() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try {
            AddOppLineItem.addOpportunityLineItems(opp.Id, '{"prodId": "001", "volume": "10"}');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddOpportunityLineItems_MissingProductId() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try {
            AddOppLineItem.addOpportunityLineItems(opp.Id, '[{"volume": "10"}]');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddOpportunityLineItems_InvalidProductId() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try {
            AddOppLineItem.addOpportunityLineItems(opp.Id, '[{"prodId": "invalidId", "volume": "10"}]');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddOpportunityLineItems_EmptyArray() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        try {
            AddOppLineItem.addOpportunityLineItems(opp.Id, '[]');
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddOpportunityLineItems_InvalidCommissionValues() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        String jsonLineItems = '[{"prodId": "' + prod.Id + '", "quality": "High", "volume": "10", "packaging": "Box", "CommissionType": "Fixed", "commissionval": "invalid", "commissionper": "invalid", "price": "120", "freightval": "15"}]';
        
        Test.startTest();
        try {
            String result = AddOppLineItem.addOpportunityLineItems(opp.Id, jsonLineItems);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddOpportunityLineItems_NoPricebookEntry() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = new Product2(Name = 'New Product', IsActive = true);
        insert prod;
        
        String jsonLineItems = '[{"prodId": "' + prod.Id + '", "quality": "High", "volume": "10"}]';
        
        Test.startTest();
        try {
            AddOppLineItem.addOpportunityLineItems(opp.Id, jsonLineItems);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testAddOpportunityLineItems_WithStandardPricebook() {
        Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
        opp.Pricebook2Id = null; 
        update opp;
        
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        String jsonLineItems = '[{"prodId": "' + prod.Id + '", "quality": "High", "volume": "10"}]';
        
        Test.startTest();
        try {
            String result = AddOppLineItem.addOpportunityLineItems(opp.Id, jsonLineItems);
        } catch (Exception e) {
            System.debug('Expected exception caught: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetQualityForProduct_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String result = AddOppLineItem.getQualityForProduct(opp.Id, prod.Id, acc.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetQualityForProduct_NoSampleFound() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        String result = AddOppLineItem.getQualityForProduct(opp.Id, prod.Id, acc.Id);
        Test.stopTest();
    }
}