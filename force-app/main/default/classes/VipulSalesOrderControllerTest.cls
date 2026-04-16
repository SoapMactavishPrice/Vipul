@isTest
public class VipulSalesOrderControllerTest {
    @testSetup
    static void setupTestData() {
        
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
        
        // Create a test user
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Country__c= testCountry.id,
            City__c=testCity.id,
            State__c=testState.id,
            Area__c=testArea.id,
            Street__c='MBP Road',
            Pin_Code__c=testPostalCode.id,
            INCO_Terms__c = 'DDP'
        );
        insert testAccount;

        // Create Contact
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'Prashantpadal@finessedirect.com', AccountId = testAccount.Id);
        insert testContact;
        
        Company_Name__c comp = new Company_Name__c(Name = 'Test');
        insert comp;

        // Create Company Bank
        Company_Bank__c testBank = new Company_Bank__c(Name = 'Test Bank', Beneficiary_Name__c = 'Test Beneficiary', SWIFT_Code__c = 'TESTSWIFT', Account_Number__c = '123456789', Company_Information__c = comp.id);
        insert testBank;
        
        Address_Information__c billToAddress = new Address_Information__c(
            Country__c= testCountry.id,
            City__c=testCity.id,
            State__c=testState.id,
            Area__c=testArea.id,
            Street__c='MBP Road',
            Pin_Code__c=testPostalCode.id,
            GSTIN__c = '123456789',
            GST_Type__c = 'Composition Levy',
            Account__c = testAccount.Id
        );
        insert billToAddress;

        // Create Proforma Invoice
        Proforma_Invoice__c testPI = new Proforma_Invoice__c(
            Name = 'Test PI',
           // Proforma_Invoice_Number__c = 'PI12345',
            Proforma_Invoice_Type__c = 'Domestic',
            Account_Name__c = testAccount.Id,
            Contact_Name__c = testContact.Id,
            CurrencyIsoCode = 'INR',
          //  Total_Price__c = 5000,
            SO_Date__c = Date.today(),
            Buyer_s_Date__c = Date.today(),
            Shipment_Date__c = Date.today(),
            Revision_Date__c = Date.today(),
            Company_Bank__c = testBank.Id,
            Delivery_Address_Same_As_Consignee__c = true,
            Payment_Terms__c = '120 days from B/L date',
            Delivery_Address1__c = billToAddress.id
        );
        insert testPI;

        // Create Proforma Invoice Line Item
        Proforma_Invoice_Line_Item__c testPILI = new Proforma_Invoice_Line_Item__c(
           // Name = 'Test PI Line',
            Proforma_Invoice_Name__c = testPI.Id,
            Quantity__c = 10,
            Sales_Price__c = 500
          //  Total_Price__c = 5000
        );
        insert testPILI;
    }

    @isTest
    static void testControllerInitialization() {
        Test.startTest();
        // Set Page parameters
        ApexPages.currentPage().getParameters().put('id', [SELECT Id FROM Proforma_Invoice__c LIMIT 1].Id);

        // Instantiate the controller
        VipulSalesOrderController controller = new VipulSalesOrderController();
		controller.save();
        controller.saveAndSend();
        controller.cancel();
       
        Test.stopTest();
    }

    @isTest
    static void testControllerWithInternationalInvoice() {
        // Create an International Proforma Invoice
        Proforma_Invoice__c intPI = new Proforma_Invoice__c(
            Name = 'International PI',
           // Proforma_Invoice_Number__c = 'PI54321',
            Proforma_Invoice_Type__c = 'International',
            CurrencyIsoCode = 'USD'
        );
        insert intPI;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', intPI.Id);
        VipulSalesOrderController controller = new VipulSalesOrderController();
		controller.save();
       // controller.saveAndSend();
        controller.cancel();

        Test.stopTest();
    }

}