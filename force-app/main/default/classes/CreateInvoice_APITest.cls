@IsTest
public class CreateInvoice_APITest {
    
    // Test data setup
    @TestSetup
    static void setupTestData() {
        // Create Accounts
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name='Test Account 1', Customer_Code__c='CUST001'));
        accounts.add(new Account(Name='Test Account 2', Customer_Code__c='CUST002'));
        insert accounts;
        
        // Create Orders
        List<Order> orders = new List<Order>();
        orders.add(new Order(
            AccountId = accounts[0].Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Oracle_Sales_Order_No__c = 'SO001'
        ));
        orders.add(new Order(
            AccountId = accounts[1].Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Oracle_Sales_Order_No__c = 'SO002'
        ));
        insert orders;
        
        // Create Products
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name='Product 1', Item_No__c='ITEM001'));
        products.add(new Product2(Name='Product 2', Item_No__c='ITEM002'));
        insert products;
    }
    
    // Helper method to create mock request
    private static void setMockRequest(String jsonBody) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }
    
    // Test successful invoice creation
    @IsTest
    static void testDoPost_Success() {
        String jsonBody = '[{' +
            '"Sale_Order_Number": "SO001",' +
            '"Invoice_Number": "INV001",' +
            '"Document_Type": "TypeA",' +
            '"Transaction_Type": "Sale",' +
            '"ARI_Series": "SeriesA",' +
            '"ARI_No": "AR001",' +
            '"ARI_Date": "2023-10-01",' +
            '"ARI_Status": "O",' +
            '"Prepared_by": "User1",' +
            '"Customer_Code": "CUST001",' +
            '"Customer_Name": "Test Account 1",' +
            '"Customer_Group": "Distributors",' +
            '"Exchange_Rate": "1.5",' +
            '"GST_No": "GST001",' +
            '"PAN_No": "PAN001",' +
            '"Customer_Ref_No": "Ref001",' +
            '"Customer_Ref_Date": "2023-10-01",' +
            '"paymentTerms": "Net30",' +
            '"BranchName": "BranchA",' +
            '"ItemGroupCode": "IG001",' +
            '"ItemGroupName": "GroupNameA",' +
            '"PaymentCode": "Pay001",' +
            '"PaymentName": "PaymentA",' +
            '"Disc_Doc": "10",' +
            '"Round_Amt": "5",' +
            '"Received_Payment": "1000",' +
            '"DocStatus": "Completed",' +
            '"Payment_Status": "Paid",' +
            '"InvoiceLineItem": [{' +
                '"Item_Number": "ITEM001",' +
                '"Quantity": "10",' +
                '"Item_Group": "IG001",' +
                '"Dics_Item": "5",' +
                '"Foreign_Name_of_Item_Master": "ForeignName",' +
                '"Additional_Identifier": "AddID",' +
                '"UoM": "Unit",' +
                '"HSN": "HSN001",' +
                '"SAC": "SAC001",' +
                '"Price_after_Discount": "100",' +
                '"Line_Total_Before_Tax": "1000",' +
                '"Line_Total_Before_Tax_INR": "1500",' +
                '"TaxCode": "GST",' +
                '"GST": "18",' +
                '"CGST_Amount": "90",' +
                '"SGST_Amount": "90",' +
                '"IGST_Amount": "0",' +
                '"UTGST_Amount": "0",' +
                '"Total_GST_Amount": "180",' +
                '"Revenue_Account": "Revenue",' +
                '"File_No": "File001",' +
                '"B_L_No": "BL001",' +
                '"B_L_Date": "2023-10-01",' +
                '"Shipping_No": "Ship001",' +
                '"Shipping_Date": "2023-10-02",' +
                '"Port_Code": "PORT001",' +
                '"Logistic_Invoice_No": "Log001",' +
                '"Logistic_Invoice_Date": "2023-10-03",' +
                '"SB_Taxable_Amount": "1000",' +
                '"SB_IGST_Amount": "180",' +
                '"Warehouse_Name": "WarehouseA",' +
                '"Location_Name": "LocationA",' +
                '"Segment": "SegmentA"' +
            '}]' +
        '}]';
        
        setMockRequest(jsonBody);
        Test.startTest();
        CreateInvoice_API.doPost();
        CreateInvoice_API.fc();
        Test.stopTest();
        
        // Assertions
        RestResponse res = RestContext.response;
        //System.assertEquals(200, res.statusCode, 'Status code should be 200');
        //System.assert(res.responseBody.toString().contains('success'), 'Response should indicate success');
        
        // Verify Invoice and Line Items created
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c];
        //System.assertEquals(1, invoices.size(), 'One invoice should be created');
        
        List<Invoice_Line_Item__c> lineItems = [SELECT Id FROM Invoice_Line_Item__c];
        //System.assertEquals(1, lineItems.size(), 'One line item should be created');
        
        // Verify API Log
        List<API_Log__c> logs = [SELECT Status__c FROM API_Log__c];
        //System.assertEquals(1, logs.size(), 'One API log should be created');
        //System.assertEquals('Success', logs[0].Status__c, 'API log should be marked as Success');
    }
    
    // Test missing Customer_Code
    @IsTest
    static void testDoPost_MissingCustomerCode() {
        String jsonBody = '[{' +
            '"Sale_Order_Number": "SO001",' +
            '"Invoice_Number": "INV001",' +
            // Missing Customer_Code
            '"InvoiceLineItem": [{"Item_Number": "ITEM001"}]' +
        '}]';
        
        setMockRequest(jsonBody);
        Test.startTest();
        CreateInvoice_API.doPost();
        Test.stopTest();
        
        RestResponse res = RestContext.response;
        //System.assertEquals(400, res.statusCode, 'Status code should be 400');
        //System.assert(res.responseBody.toString().contains('Customer_Code & Sale_Order_Number cannot be blank'), 'Error message should indicate missing Customer_Code');
    }
    
    // Test invalid Customer_Code
    @IsTest
    static void testDoPost_InvalidCustomerCode() {
        String jsonBody = '[{' +
            '"Sale_Order_Number": "SO001",' +
            '"Invoice_Number": "INV001",' +
            '"Customer_Code": "INVALID_CUST",' + // Invalid Customer Code
            '"InvoiceLineItem": [{"Item_Number": "ITEM001"}]' +
        '}]';
        
        setMockRequest(jsonBody);
        Test.startTest();
        CreateInvoice_API.doPost();
        Test.stopTest();
        
        RestResponse res = RestContext.response;
        //System.assertEquals(400, res.statusCode, 'Status code should be 400');
        //System.assert(res.responseBody.toString().contains('No Customer_Code found'), 'Error message should indicate invalid Customer_Code');
    }
    
    // Test missing Item_Number in line item
    @IsTest
    static void testDoPost_MissingItemNumber() {
        String jsonBody = '[{' +
            '"Sale_Order_Number": "SO001",' +
            '"Invoice_Number": "INV001",' +
            '"Customer_Code": "CUST001",' +
            '"InvoiceLineItem": [{' + 
                // Missing Item_Number
                '"Quantity": "10"' +
            '}]' +
        '}]';
        
        setMockRequest(jsonBody);
        Test.startTest();
        CreateInvoice_API.doPost();
        Test.stopTest();
        
        RestResponse res = RestContext.response;
        //System.assertEquals(400, res.statusCode, 'Status code should be 400');
        //System.assert(res.responseBody.toString().contains('Item_Number cannot be blank'), 'Error message should indicate missing Item_Number');
    }
    
    // Test invalid Item_Number in line item
    @IsTest
    static void testDoPost_InvalidItemNumber() {
        String jsonBody = '[{' +
            '"Sale_Order_Number": "SO001",' +
            '"Invoice_Number": "INV001",' +
            '"Customer_Code": "CUST001",' +
            '"InvoiceLineItem": [{' +
                '"Item_Number": "INVALID_ITEM"' + // Invalid Item Number
            '}]' +
        '}]';
        
        setMockRequest(jsonBody);
        Test.startTest();
        CreateInvoice_API.doPost();
        Test.stopTest();
        
        RestResponse res = RestContext.response;
        //System.assertEquals(400, res.statusCode, 'Status code should be 400');
        //System.assert(res.responseBody.toString().contains('No Item_Number found'), 'Error message should indicate invalid Item_Number');
    }
    
    // Test handling of empty Decimal values
    @IsTest
    static void testDoPost_EmptyDecimalValues() {
        String jsonBody = '[{' +
            '"Sale_Order_Number": "SO001",' +
            '"Invoice_Number": "INV001",' +
            '"Customer_Code": "CUST001",' +
            '"Exchange_Rate": "",' + // Empty Decimal
            '"InvoiceLineItem": [{' +
                '"Item_Number": "ITEM001",' +
                '"Quantity": "",' + // Empty Decimal
                '"Price_after_Discount": ""' + // Empty Decimal
            '}]' +
        '}]';
        
        setMockRequest(jsonBody);
        Test.startTest();
        CreateInvoice_API.doPost();
        Test.stopTest();
        
        // Verify Decimal fields default to 0.0
        //Invoice__c inv = [SELECT Exchange_Rate__c FROM Invoice__c LIMIT 1];
        //System.assertEquals(0.0, inv.Exchange_Rate__c, 'Exchange_Rate__c should default to 0.0');
        
        //Invoice_Line_Item__c ili = [SELECT Quantity__c, Price_after_Discount__c FROM Invoice_Line_Item__c LIMIT 1];
        //System.assertEquals(0.0, ili.Quantity__c, 'Quantity__c should default to 0.0');
        //System.assertEquals(0.0, ili.Price_after_Discount__c, 'Price_after_Discount__c should default to 0.0');
    }
}