@IsTest
public class ProformaSampleOutRequestTest {

    @IsTest
    static void testAllInOne() {

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Enquiry',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opp;

        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            CI_no__c = 'CI-001'
        );
        insert prod;

        Unit_Master__c unit = new Unit_Master__c(
            Name = 'Test Unit',
            Sample_Warehouse__c = true
        );
        insert unit;

        Proforma_Invoice__c pi = new Proforma_Invoice__c(
            Account_Name__c = acc.Id,
            Enquiry_Name__c = opp.Id,
            CurrencyIsoCode = 'USD'
        );
        insert pi;

        Proforma_Invoice_Line_Item__c li = new Proforma_Invoice_Line_Item__c(
            Proforma_Invoice_Name__c = pi.Id,
            Product__c = prod.Id,
            Quantity__c = 10,
            Quality__c = 'High'
        );
        insert li;

        Map<Object, Object> productRow = new Map<Object, Object>{
            'unitId' => unit.Id,
            'prodId' => prod.Id,
            'quantity' => 5,
            'packet' => 'P1',
            'quality' => 'Medium',
            'colourIndex' => 'CI',
            'application' => 'Test',
            'New_Product__c' => false
        };

        List<Object> products = new List<Object>();
        products.add(productRow);

        Map<String, Object> requestData = new Map<String, Object>{
            'accountId' => acc.Id,
            'enquiryId' => opp.Id,
            'quoteId' => null,
            'countryId' => null,
            'personId' => UserInfo.getUserId(),
            'proformaInvoiceId' => pi.Id,
            'products' => products
        };

        Test.startTest();
        ProformaSampleOutRequest.getProformaInvoiceData(pi.Id);
        ProformaSampleOutRequest.getUnitsForSampleWarehouse('Test');
        ProformaSampleOutRequest.createSampleOutRequest(requestData);
        ProformaSampleOutRequest.getProductCI(prod.Id);
        Test.stopTest();
    }
}