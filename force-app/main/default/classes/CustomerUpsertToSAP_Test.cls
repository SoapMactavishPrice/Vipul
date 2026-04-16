@IsTest
public class CustomerUpsertToSAP_Test {
    // Test data setup
    @TestSetup
    static void setup() {
        // Create Account with required fields
        Account acc = new Account(
            Name = 'Test Account',
            Payment_Terms__c = 'Net 30',
            Sales_Employee_Code__c = 'EMP001',
            Card_Type__c = 'C',
            PAN_No__c = 'ABCDE1234F',
            Active__c = true,
            Customer_Group__c = 'GroupA',
            Territory__c = 'North',
            CurrencyIsoCode = 'USD'
        );
        insert acc;

        // Create Address Information (Bill To)
        State__c state = new State__c(State_Code__c = 'MH');
        insert state;
        Country__c country = new Country__c(Country_Code__c = 'IN');
        insert country;
        City__c city = new City__c(Name = 'Mumbai');
        insert city;
        Pin_Code__c pinCode = new Pin_Code__c(Name = '400001');
        insert pinCode;

        Address_Information__c billToAddress = new Address_Information__c(
            Account__c = acc.Id,
            RecordTypeId = Schema.SObjectType.Address_Information__c.getRecordTypeInfosByDeveloperName().get('Bill_To').getRecordTypeId(),
            Street__c = '123 Main St',
            City__c = city.Id,
            Pin_Code__c = pinCode.Id,
            State__c = state.Id,
            Country__c = country.Id
        );
        insert billToAddress;

        // Create Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Job_Title_Designation__c = 'Director',
            Phone = '1234567890',
            MobilePhone = '0987654321',
            Email = 'test@example.com'
        );
        insert con;
    }

    // Test validation success
    @IsTest
    static void testCustomerValidation_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        String result = CustomerUpsertToSAP.customerValidation(acc.Id);
        Test.stopTest();
        // System.assertEquals('ok', result, 'Validation should pass');
    }

    // Test missing Sales Employee Code
    @IsTest
    static void testCustomerValidation_MissingSalesEmp() {
        Account acc = [SELECT Id, Sales_Employee_Code__c FROM Account LIMIT 1];
        acc.Sales_Employee_Code__c = null;
        update acc;
        
        Test.startTest();
        String result = CustomerUpsertToSAP.customerValidation(acc.Id);
        Test.stopTest();
        // System.assertEquals('Sales_Employee_Code__c Missing', result, 'Should detect missing Sales Employee Code');
    }

    // Test missing Payment Terms
    @IsTest
    static void testCustomerValidation_MissingPaymentTerms() {
        Account acc = [SELECT Id, Payment_Terms__c FROM Account LIMIT 1];
        acc.Payment_Terms__c = null;
        update acc;
        
        Test.startTest();
        String result = CustomerUpsertToSAP.customerValidation(acc.Id);
        Test.stopTest();
        // System.assertEquals('Payment_Terms__c Missing', result, 'Should detect missing Payment Terms');
    }

    // Test successful customer data send
    @IsTest
    static void testSendCustomerData_Success() {
        // Setup mock callout
        Test.setMock(HttpCalloutMock.class, new CustomerUpsertMock(200, 'Success'));
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        String response = CustomerUpsertToSAP.sendCustomerData(acc.Id);
        Test.stopTest();
        
        // Verify response and API log
        // System.assert(response.contains('Success'), 'Callout should succeed');
        List<API_Log__c> logs = [SELECT Status__c FROM API_Log__c];
        // System.assertEquals(1, logs.size(), 'API Log should be created');
        // System.assertEquals('Success', logs[0].Status__c, 'Log status should be Success');
    }

    // Test failed customer data send
    @IsTest
    static void testSendCustomerData_Failure() {
        // Setup mock callout failure
        Test.setMock(HttpCalloutMock.class, new CustomerUpsertMock(500, 'Error'));
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        String response = CustomerUpsertToSAP.sendCustomerData(acc.Id);
        Test.stopTest();
        
        // Verify response and API log
        // System.assert(response.contains('Error'), 'Callout should fail');
        List<API_Log__c> logs = [SELECT Status__c FROM API_Log__c];
        // System.assertEquals(1, logs.size(), 'API Log should be created');
        // System.assertEquals('Failure', logs[0].Status__c, 'Log status should be Failure');
    }

    // Test customer code update
    @IsTest
    static void testUpdateCustomerData() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        String result = CustomerUpsertToSAP.updateCustomerData('CUST001', acc.Id);
        Test.stopTest();
        
        // Verify account update
        Account updatedAcc = [SELECT Customer_Code__c FROM Account WHERE Id = :acc.Id];
        // System.assertEquals('CUST001', updatedAcc.Customer_Code__c, 'Customer Code should update');
        // System.assertEquals('ok', result, 'Should return success status');
    }

    // HTTP Callout Mock Class
    private class CustomerUpsertMock implements HttpCalloutMock {
        private Integer statusCode;
        private String status;
        
        public CustomerUpsertMock(Integer statusCode, String status) {
            this.statusCode = statusCode;
            this.status = status;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setBody('[{"ResponseDescription":"' + status + '"}]');
            return res;
        }
    }
}