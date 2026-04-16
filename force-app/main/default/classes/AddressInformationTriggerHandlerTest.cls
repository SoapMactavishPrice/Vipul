@IsTest
public class AddressInformationTriggerHandlerTest {
    
    @IsTest
    static void testHandleCopyBillToShipTo() {
        // Step 1: Create a test account with a valid CurrencyIsoCode
        Account testAccount = new Account(
            Name = 'Test Account',
            INCO_Terms__c = 'DDP',
            CurrencyIsoCode = 'USD' // Set to a valid currency to bypass the validation rule
        );
        insert testAccount;
        
        Country__c testCountry = new Country__c(Name = 'India');
        insert testCountry;
        
        State__c state = new State__c(Name = 'Test State', Country__c = testCountry.Id);
        insert state;
        
        City__c city = new City__c(Name = 'Test City', State__c = state.Id);
        insert city;
        
        Area__c area = new Area__c(Name = 'Test Area', City__c = city.Id);
        insert area;
        
        Pin_Code__c postalCode = new Pin_Code__c(Name = '12345', Area__c = area.Id);
        insert postalCode;

        // Step 2: Fetch the Ship_To record type ID
        Id shipToRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Address_Information__c' AND DeveloperName = 'Ship_To' LIMIT 1].Id;

        // Step 3: Create a Bill_To Address record
        Address_Information__c billToAddress = new Address_Information__c(
            City__c = city.Id,
            State__c = state.Id,
            Country__c = testCountry.Id,
            Area__c = area.Id,
            Pin_Code__c = postalCode.Id,
            Street__c = 'ABC',
            GSTIN__c = '123456789',
            GST_Type__c = 'Composition Levy',
            Account__c = testAccount.Id,
            Copy_from_Bill_To_to_Ship_To__c = true
        );
        insert billToAddress;

        // Step 4: Verify the Ship_To Address creation
        List<Address_Information__c> shipToAddresses = [SELECT Name, City__c, State__c, Area__c, Street__c, Pin_Code__c,
                                                         Country__c, GSTIN__c, GST_Type__c, Account__c, RecordTypeId
                                                         FROM Address_Information__c
                                                         WHERE RecordTypeId = :shipToRecordTypeId];

        System.assertEquals(1, shipToAddresses.size(), 'One Ship_To record should be created.');
        Address_Information__c shipToAddress = shipToAddresses[0];
    }
}