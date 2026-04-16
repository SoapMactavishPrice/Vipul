public class GetCustomerLedger_FromSAP {
 
    public static void getCustomerLedgerData(){

        Date todayDate = Date.today();
        DateTime todayDateTime = DateTime.newInstance(todayDate, Time.newInstance(0, 0, 0, 0));

        String formatted_T_Date = todayDateTime.format('yyyyMMdd');
        System.debug(formatted_T_Date);


        API_Log__c api_log = new API_Log__c();
        api_log.API_log_Name__c = 'GetCustomerLedger_FromSAP';
        api_log.Request_Created_Time__c = Datetime.now();

        try {

            // Initialize the HTTP request
            HttpRequest req = new HttpRequest();
            Http http = new Http();

            // String endpointURL = label.ledgerEndpoint+'20250823';
            String endpointURL = label.ledgerEndpoint+formatted_T_Date;
            api_log.Request__c = endpointURL;

            // Set the endpoint (URL)
            req.setEndpoint(endpointURL);
            req.setMethod('GET');
            req.setTimeout(120000);

            // Set headers
            // req.setHeader('SOAPAction', apiparam.SOAPAction);
            // req.setHeader('Content-Type', apiparam.ContentType);
            // req.setHeader('Authorization', HttpUtils.createBasicAuthHeader(apiparam.Username, apiparam.Password));

            HttpResponse res = http.send(req);

            System.debug(res.getBody());

            String jsonBody = res.getBody();
            // api_log.Response__c = jsonBody;

            
            if (res.getStatusCode() == 200) {
                
                List<Customer_Ledger__c> customerLedgerListInsert = new List<Customer_Ledger__c>();
                List<Customer_Ledger__c> exCustomerLedgerList = new List<Customer_Ledger__c>();

                // Parse the JSON
                List<Object> results = (List<Object>)JSON.deserializeUntyped(jsonBody);
                
                if (results.size() > 0) {

                    Set<String> custCodeSet = new Set<String>();
                    Map<Object, String> custCodeMap = new Map<Object, String>();

                    for(Object obj : results) {
                        Map<String, Object> customerData = (Map<String, Object>)obj;
                        String customerCode = (String)customerData.get('CardCode');
                        custCodeSet.add(customerCode);
                    }

                    System.debug(custCodeSet);
                    
                    List<Account> accList = [SELECT Id, Name, Customer_Code__c FROM Account WHERE Customer_Code__c IN: custCodeSet];
                    
                    System.debug(accList);
                    
                    for(Account acc : accList) {
                        custCodeMap.put(acc.Customer_Code__c, acc.Id);
                    }

                    exCustomerLedgerList = [SELECT Id, Name, Account_Name__c, Customer_Code__c FROM Customer_Ledger__c WHERE Customer_Code__c IN :custCodeSet];

                    // Insert Customer Ledger
                    for(Object obj : results) {

                        Map<String, Object> customerData = (Map<String, Object>)obj;
                        String customerCode = (String)customerData.get('CardCode');
                        if (custCodeMap.containsKey(customerCode)) {
                            Customer_Ledger__c customerLedger = new Customer_Ledger__c();
                            DateTime now = DateTime.now();
                            String formatted = now.format('yyyy-MM-dd HH:mm:ss', 'Asia/Kolkata');
                            customerLedger.Name = customerCode+' - '+formatted;
                            customerLedger.Account_Name__c = (String)custCodeMap.get((String)customerData.get('CardCode'));
                            customerLedger.Customer_Code__c = (String)customerData.get('CardCode');
                            customerLedger.Customer_Group_Code__c = (String)customerData.get('CustomerGroupCode');
                            customerLedger.Customer_Group__c = (String)customerData.get('CustomerGroup');
                            customerLedger.Phone__c = (String)customerData.get('Phone');
                            customerLedger.Mobile__c = (String)customerData.get('Mobile');
                            // customerLedger.Email__c = (String)customerData.get('Email');
                            // customerLedger.Contact_Person__c = (String)customerData.get('ContactPerson'); // Need to check
                            customerLedger.Address__c = (String)customerData.get('Address');
                            customerLedger.Pincode__c = (String)customerData.get('Pincode');
                            customerLedger.City__c = (String)customerData.get('City');
                            customerLedger.State__c = (String)customerData.get('State');
                            customerLedger.CurrencyIsoCode = (String)customerData.get('Currency') == '##' ? 'INR' : (String)customerData.get('Currency');
                            customerLedger.Sales_Employee_Code__c = (String)customerData.get('SalesEmployeeCode');
                            customerLedger.Sales_Employee_Name__c = (String)customerData.get('SalesEmployeeName');
                            customerLedger.Country__c = (String)customerData.get('Country');
                            customerLedger.Credit_Limit__c = Decimal.valueOf((String)customerData.get('CreditLimit'));
                            customerLedger.Current_Balance__c = Decimal.valueOf((String)customerData.get('CurrentBalance'));
                            customerLedger.Delivery_Balance__c = Decimal.valueOf((String)customerData.get('DeliveryBalance'));
                            customerLedger.Order_Balance__c = Decimal.valueOf((String)customerData.get('OrderBalance'));
                            customerLedgerListInsert.add(customerLedger);
                        }
                    }

                    if(customerLedgerListInsert.size() > 0) {
                        insert customerLedgerListInsert;
                        if(exCustomerLedgerList.size() > 0) {
                            delete exCustomerLedgerList;
                        }
                    }

                } else {
                    
                }

                api_log.Status__c = 'Success';
                api_log.Response_Code__c = '200';

            } else {

                api_log.Status__c = 'Failure';
                api_log.Response_Code__c = String.valueOf(res.getStatusCode());

            }

            api_log.response_time__c = Datetime.now();
            
        } catch (Exception e) {
            System.debug('Catch Error' + e.getStackTraceString());
            System.debug('Catch Error' + e.getMessage());
            System.debug('Catch Error' + e.getlineNumber());
            
            api_log.Status__c = 'Failure';
            api_log.Response_Code__c = '400';
            api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            api_log.response_time__c = Datetime.now();
            
        }
        
        insert api_log;

    }
    
}