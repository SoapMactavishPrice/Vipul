@isTest
public class NewSampleRequestTest {

    @isTest
    static void testNewSampleRequestMethods() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Country__c country = new Country__c(Name = 'Test Country');
        insert country;

        Unit_Master__c unit = new Unit_Master__c(Name = 'Test Unit');
        insert unit;

        Product2 prod = new Product2(Name = 'Test Product');
        insert prod;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = acc.Id);
        insert opp;

        Sample_Out__c sampleOut = new Sample_Out__c( Sample_Request__c = null);
        insert sampleOut;

        Sample_In__c sampleIn = new Sample_In__c( Sample_Request__c = null);
        insert sampleIn;

        List<Map<String, Object>> products = new List<Map<String, Object>>();
        Map<String, Object> productMap = new Map<String, Object>();
        productMap.put('prodId', prod.Id);
        productMap.put('quantity', 10);
        productMap.put('packet', 'Test Packet');
        productMap.put('quality', 'High');
        productMap.put('ciNo', 'CINO1');
        productMap.put('application', 'App1');
        productMap.put('unitOfMeasure', 'Kilogram (Kg)');
        productMap.put('unitId', unit.Id);
        productMap.put('productName', 'Test Product');
        productMap.put('ci', 'CI');
        productMap.put('srefno', 'SREF1');
        productMap.put('courierno', 'C123456');
        productMap.put('annualQtyOfBusiness', 500);
        products.add(productMap);

        User usr = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];

        Id createdId1 = NewSampleRequest.createSampleRequest(
            opp.Id,
            'Internal',
            Date.today(),
            Date.today(),
            usr.Id,
            acc.Id,
            opp.Id,
            country.Id,
            unit.Id,
            '2',
            0,
            'SampleOut',
            '',
            'CINO1',
            'CI',
            'SREF1',
            'Kilogram (Kg)',
            products
        );

        Id createdId2 = NewSampleRequest.createSampleRequest(
            opp.Id,
            'External',
            Date.today(),
            Date.today(),
            usr.Id,
            acc.Id,
            opp.Id,
            country.Id,
            unit.Id,
            '2',
            0,
            '',
            'SampleIn',
            'CINO1',
            'CI',
            'SREF1',
            'Kilogram (Kg)',
            products
        );

        List<Sample_Out__c> outList = NewSampleRequest.getSampleOutOptions();
        List<Sample_In__c> inList = NewSampleRequest.getSampleInOptions();
        List<User> userList = NewSampleRequest.getUserOptions();
        List<Map<String, String>> sentToOptions = NewSampleRequest.getSamplesRequestSentToOptions();
        List<Product2> prodList = NewSampleRequest.getProductOptions();
        List<Opportunity> opps = NewSampleRequest.searchOpportunities('Test');
        Map<String, String> accCountry = NewSampleRequest.getAccountAndCountryDetails(acc.Id);
        Map<String, String> currentUser = NewSampleRequest.getCurrentUserName();
        List<Map<String, String>> unitOfMeasureOptions = NewSampleRequest.getUnitOfMeasureOptions();
    }
}