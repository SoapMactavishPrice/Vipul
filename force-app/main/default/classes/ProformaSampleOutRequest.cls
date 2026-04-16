public with sharing class ProformaSampleOutRequest {

    /* =========================================================
       FETCH PROFORMA + LINE ITEMS
       ========================================================= */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getProformaInvoiceData(Id proformaInvoiceId) {

        Map<String, Object> result = new Map<String, Object>();

        Proforma_Invoice__c proforma = [
            SELECT Id,
                   Account_Name__c,
                   Enquiry_Name__c,
                   Country_of_Final_Destination__c,
                   Quote__c,
                   CurrencyIsoCode
            FROM Proforma_Invoice__c
            WHERE Id = :proformaInvoiceId
            LIMIT 1
        ];

        result.put('accountId', proforma.Account_Name__c);
        result.put('enquiryId', proforma.Enquiry_Name__c);
        result.put('countryId', proforma.Country_of_Final_Destination__c);
        result.put('quoteId', proforma.Quote__c);
        result.put('accountCurrency', proforma.CurrencyIsoCode);

        User u = [
            SELECT Id, Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        result.put('personId', u.Id);
        result.put('filledByName', u.Name);

        /* ================= LINE ITEMS ================= */
        List<Proforma_Invoice_Line_Item__c> lineItems = [
            SELECT Id,
                   Product__c,
                   Product__r.CI_no__c,
                   Quantity__c,
                   Quality__c
            FROM Proforma_Invoice_Line_Item__c
            WHERE Proforma_Invoice_Name__c = :proformaInvoiceId
        ];

        List<Map<String, Object>> rows = new List<Map<String, Object>>();

        for (Proforma_Invoice_Line_Item__c li : lineItems) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('productId', li.Product__c);
            row.put('ciNo', li.Product__r != null ? li.Product__r.CI_no__c : null);
            row.put('quantity', li.Quantity__c);
            row.put('quality', li.Quality__c);
            row.put('packets', null);
            row.put('colourIndex', null);
            row.put('application', null);
            rows.add(row);
        }

        result.put('lineItems', rows);
        return result;
    }

    /* =========================================================
       UNIT LOOKUP
       ========================================================= */
    @AuraEnabled(cacheable=true)
    public static List<Unit_Master__c> getUnitsForSampleWarehouse(String searchKey) {

        String key = '%' + (searchKey == null ? '' : searchKey) + '%';

        return [
            SELECT Id, Name
            FROM Unit_Master__c
            WHERE Sample_Warehouse__c = true
            AND Name LIKE :key
            ORDER BY Name
            LIMIT 20
        ];
    }

    /* =========================================================
       CREATE SAMPLE OUT REQUEST
       ========================================================= */
  @AuraEnabled
public static Id createSampleOutRequest(Map<String, Object> requestData) {

    System.debug('### REQUEST DATA ### ' + requestData);

    if (requestData == null) {
        throw new AuraHandledException('Request data is missing.');
    }

    /* ================= SAFE CAST ================= */
    Object rawProducts = requestData.get('products');
    System.debug('### RAW PRODUCTS ### ' + rawProducts);

    if (rawProducts == null) {
        throw new AuraHandledException('Products key missing in request.');
    }

    List<Object> productList = (List<Object>) rawProducts;
    System.debug('### PRODUCT LIST SIZE ### ' + productList.size());

    if (productList.isEmpty()) {
        throw new AuraHandledException('No products found to process.');
    }

    Id accountId = (Id) requestData.get('accountId');
    Id enquiryId = (Id) requestData.get('enquiryId');
    Id quoteId   = (Id) requestData.get('quoteId');
    Id countryId = (Id) requestData.get('countryId');
    Id personId  = (Id) requestData.get('personId');
    Id proformaInvoiceId  = (Id) requestData.get('proformaInvoiceId');

    /* ================= CREATE REQUEST ================= */
    Sample_Out_Request__c req = new Sample_Out_Request__c(
        Company_Name__c = accountId,
        Enquiry_Name__c = enquiryId,
        Quote__c        = quoteId,
        Country__c      = countryId,
        Person__c       = personId,
        Proforma_Invoice__c = proformaInvoiceId
    );
    insert req;

    List<Sample_Out__c> sampleLines = new List<Sample_Out__c>();

    Integer rowNo = 0;

    for (Object obj : productList) {
    rowNo++;

    // ❌ WRONG (causes your error)
    // Map<String, Object> p = (Map<String, Object>) obj;

    // ✅ CORRECT
    Map<Object, Object> rawMap = (Map<Object, Object>) obj;
    Map<String, Object> p = new Map<String, Object>();

    for (Object key : rawMap.keySet()) {
        p.put(String.valueOf(key), rawMap.get(key));
    }

    System.debug('### ROW ' + rowNo + ' NORMALIZED MAP ### ' + p);

    Id unitId   = (Id) p.get('unitId');
    Boolean isNew = (Boolean) p.get('New_Product__c');
    Id prodId   = (Id) p.get('prodId');

    /* ================= VALIDATION ================= */
    if (unitId == null) {
        throw new AuraHandledException(
            'Sample Request From Unit is mandatory. Row: ' + rowNo
        );
    }

    if (isNew == false && prodId == null) {
        throw new AuraHandledException(
            'Product is required. Row: ' + rowNo
        );
    }

    Sample_Out__c so = new Sample_Out__c(
        Sample_Out_Request__c = req.Id,
        Sample_Sent_to_Unit__c = unitId,
        Quantity__c = parseDecimal(p.get('quantity')),
        Packets__c = (String) p.get('packet'),
        Quality__c = (String) p.get('quality'),
        Colour_Index_Name__c = (String) p.get('colourIndex'),
        Application__c = (String) p.get('application'),
        New_Product__c = isNew
       
    );

    if (isNew == true) {
        so.New_Product_Name__c =
            ((String) p.get('New_Product_Name__c'))?.toUpperCase();
        so.New_Product_CI_No__c =
            (String) p.get('New_Product_CI_No__c');
    } else {
        so.Product_Name__c = prodId;
    }

    sampleLines.add(so);
}


    System.debug('### INSERTING SAMPLE LINES ### ' + sampleLines.size());

    if (!sampleLines.isEmpty()) {
        insert sampleLines;
    }

    System.debug('### REQUEST CREATED ### ' + req.Id);
    return req.Id;
}

    /* =========================================================
       SAFE DECIMAL PARSER
       ========================================================= */
    private static Decimal parseDecimal(Object val) {
        try {
            return val == null ? null : Decimal.valueOf(String.valueOf(val));
        } catch (Exception e) {
            return null;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Product2 getProductCI(Id productId) {
        return [
            SELECT Id, CI_no__c
            FROM Product2
            WHERE Id = :productId
            LIMIT 1
        ];
    }

}